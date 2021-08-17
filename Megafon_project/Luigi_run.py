import luigi
import pandas as pd
import numpy as np
import pickle
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.pipeline import Pipeline, FeatureUnion
from functions import reduce_mem_usage
from datetime import datetime, date, time
from sklearn.decomposition import PCA


class DataTransform(BaseEstimator, TransformerMixin):

    def __init__(self, features):
        self.data = None
        self.target = None
        self.features = features.copy()
        self.vas_id_dict1 = None
        self.vas_id_dict2 = None
        self.vas_id_dict3 = None
        self.q_list = None
        self.first_day = None

    def fit(self, data, target):
        self.data = data.copy()
        self.target = target.astype('int')
        X = pd.concat([data, target], axis=1)
        # доля подключений услуги по сравнению с отказами
        self.vas_id_dict1 = dict(X.groupby('vas_id')['target'].mean())
        # соотношение подключений по всем услугам
        self.vas_id_dict2 = dict(X.loc[X['target'] == 1]['vas_id'].value_counts(normalize=True))
        # доля предложений услуги
        self.vas_id_dict3 = dict(X['vas_id'].value_counts(normalize=True))
        # максимальные 20% значений по признакам из features
        self.q_list = [np.quantile(self.features[el], q=0.8) for el in self.features][2:]
        self.first_day = data['buy_time'].min()

        return self

    def transform(self, data):

        if 'Unnamed: 0' in data.columns:
            data.drop(columns='Unnamed: 0', inplace=True)
        data = reduce_mem_usage(data)

        # при сравнении распределения признаков в зависимости от целевой переменной в таблице выше видно, что
        # наибольшая разница наблюдается верхнем квартиле. Посчитаем значения выше 0.8 квантиля
        self.features['highest_value'] = 0
        for i, col in enumerate(self.features.columns[2:-1]):
            self.features.loc[self.features[col] > self.q_list[i], 'highest_value'] += 1

        self.features.drop_duplicates('id', keep='first', inplace=True)
        prepared_df = pd.merge(data, self.features, how='left', on='id')

        prepared_df.rename(columns={'buy_time_x': 'buy_time'}, inplace=True)

        # будем считать кол-во дней с 1го дня train периода
        prepared_df['count_days'] = (prepared_df['buy_time'] - self.first_day) // 86400

        # доля подключений услуги по сравнению с отказами
        prepared_df['vas_id1'] = prepared_df['vas_id'].replace(self.vas_id_dict1)

        # prepared_df['vas_id2'] = prepared_df['vas_id'].replace(self.vas_id_dict2)
        # prepared_df['vas_id3'] = prepared_df['vas_id'].replace(self.vas_id_dict3)
        # prepared_df['date'] = prepared_df['buy_time'].apply(lambda x: date.fromtimestamp(x))
        # prepared_df['month'] = prepared_df['buy_time'].apply(lambda x: date.fromtimestamp(x).month)
        prepared_df['day'] = prepared_df['buy_time'].apply(lambda x: date.fromtimestamp(x).day)
        prepared_df['weekofyear'] = prepared_df['buy_time'].apply(
            lambda x: pd.to_datetime(date.fromtimestamp(x)).weekofyear)

        """
        Некоторым пользователям сделано несколько предложений. Сохраним информацию, какую услугу пользователю
        уже предлагали (каждую отдельно), сколько у него всего предложений, в какой последовательности предлагали
        услуги, какая разница по времени между предложениями услуг

        """
        tmp = prepared_df[['id', 'buy_time', 'vas_id']].merge(self.data[['id', 'buy_time', 'vas_id']], \
                                                              on=['id', 'buy_time', 'vas_id'], how='outer')
        tmp = tmp.loc[tmp['id'].isin(prepared_df['id'])]
        tmp2 = tmp.groupby('id')['vas_id'].count().reset_index()
        tmp2 = tmp2.loc[tmp2['vas_id'] > 1]
        tmp['buy_time'] = (tmp['buy_time'] - self.first_day) // 86400
        tmp.rename(columns={'buy_time': 'count_days'}, inplace=True)
        # будем считать предложения только для тех пользователей, у которых их больше 1
        tmp = tmp.loc[tmp['id'].isin(tmp2['id'])].sort_values(['id', 'count_days']).reset_index(drop=True)
        tmp['1.0'] = 0
        tmp['2.0'] = 0
        tmp['4.0'] = 0
        tmp['5.0'] = 0
        tmp['6.0'] = 0
        tmp['7.0'] = 0
        tmp['8.0'] = 0
        tmp['9.0'] = 0

        checked_id = 0
        counter = 1
        tmp['count_offers'] = 1
        tmp['time_delta'] = 0

        for i in range(tmp.shape[0]):
            if tmp.iloc[i]['id'] != checked_id:
                checked_id = tmp.iloc[i]['id']
                counter = 1
            else:
                counter += 1
                tmp.loc[i, 'count_offers'] = counter
                tmp.loc[i, 'time_delta'] = tmp.iloc[i]['count_days'] - tmp.iloc[i - 1]['count_days']
            tmp.loc[i, str(tmp.iloc[i]['vas_id'])] += 1

        prepared_df = prepared_df.merge(tmp[['id', 'vas_id', 'count_days', 'count_offers', 'time_delta']], \
                                        on=['id', 'vas_id', 'count_days'], how='left')
        prepared_df = prepared_df.merge(tmp.groupby('id').agg({'1.0': 'sum', '2.0': 'sum', '4.0': 'sum',
                                                               '5.0': 'sum', '6.0': 'sum', '7.0': 'sum', '8.0': 'sum',
                                                               '9.0': 'sum'}).reset_index(), on='id', how='left')

        # остальным пользователям проставим 1 предложение
        prepared_df['count_offers'] = prepared_df['count_offers'].fillna(1)
        prepared_df['time_delta'] = prepared_df['time_delta'].fillna(0)
        prepared_df['1.0'] = prepared_df['1.0'].fillna(0).rename('offer_1')
        prepared_df['2.0'] = prepared_df['2.0'].fillna(0).rename('offer_2')
        prepared_df['4.0'] = prepared_df['4.0'].fillna(0).rename('offer_4')
        prepared_df['5.0'] = prepared_df['5.0'].fillna(0).rename('offer_5')
        prepared_df['6.0'] = prepared_df['6.0'].fillna(0).rename('offer_6')
        prepared_df['7.0'] = prepared_df['7.0'].fillna(0).rename('offer_7')
        prepared_df['8.0'] = prepared_df['8.0'].fillna(0).rename('offer_8')
        prepared_df['9.0'] = prepared_df['9.0'].fillna(0).rename('offer_9')

        prepared_df.drop(['id', 'buy_time'], axis=1, inplace=True)

        return prepared_df

class PCA_transformer(BaseEstimator, TransformerMixin):

    def __init__(self, num_features):
        self.num_features = num_features
        # постепенно сократим кол-во компонент до 10
        self.steps = [80, 40, 25, 15, 10]
        self.X = None

    def fit(self, X, y=None):
        self.X = X.copy()
        return self

    def transform(self, X, y=None):
        data = X[self.num_features].copy()
        for step in self.steps:
            pca = PCA(n_components=step, svd_solver='full')
            data = pca.fit_transform(data)
        col_names = ['pca' + str(i) for i in range(len(data[0]))]

        return X.join(pd.DataFrame(data, columns=col_names))


class ColumnSelector(BaseEstimator, TransformerMixin):
    def __init__(self, columns):
        self.columns = columns

    def fit(self, X, y=None):
        return self

    def transform(self, X):
        assert isinstance(X, pd.DataFrame)

        try:
            return X[self.columns]
        except KeyError:
            cols_error = list(set(self.columns) - set(X.columns))
            raise KeyError("DataFrame не содердит следующие колонки: %s" % cols_error)


class PredictProbability(luigi.Task):
    test_csv = luigi.Parameter()

    def run(self):
        test = pd.read_csv(self.test_csv, float_precision="high", encoding='utf8', sep=',')

        with open('models/lgbm_pipeline.pickle', 'rb') as model_file:
            model = pickle.load(model_file)

        test['target'] = model.predict_proba(test)[:, 1]

        test.to_csv('answers_test.csv', float_format='%20f', index=False, encoding='utf8', sep=',')

    def output(self):
        return luigi.LocalTarget('answers_test.csv')



if __name__ == '__main__':
    luigi.build([PredictProbability('data_test.csv')])