## "Recommender systems" course project at Geekbrains

#### Task:
create a list of recommendations to the customers using the information 
about sales within the previous time period. We have the same customers in
all the datasets and do not have a problem of 'cold start'

#### Задача:
на основании имеющихся данных по продажам товаров за предыдущий 
период сформировать список рекомендаций пользователям на будущий период.
Мы не рассматриваем холодный старт для пользователя, все наши пользователи 
одинаковы во всех сетах

#### Stack 
sklearn, pandas, numpy, LGBMClassifier, implicit
A 2-level model is used to create the final list of recommendations:
1. Implicit TFIDF-Recommender is used to select candidates to recommend
2. LGBMClassifier is used to sort the selected candidates and predict probability

#### Data:

    retail_train - purchases within the previous time period
    product - description of the goods
    hh_demographic - description of the customers
    retail_test1 - test data for the following time period
    
#### Metrics:
precision top-5

#### Result:
0.4136

