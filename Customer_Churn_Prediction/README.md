##Customer Churn Prediction / Предсказание оттока клиентов

ML: sklearn, pandas, numpy API: flask

Dataset:  https://www.kaggle.com/blastchar/telco-customer-churn

#### Description:

Each row represents a customer, each column contains customer’s attributes described on the column Metadata.

The data set includes information about:

- Customers who left within the last month – the column is called Churn
- Services that each customer has signed up for – phone, multiple lines, internet, online security, online backup, device protection, tech support, and streaming TV and movies
- Customer account information – how long they’ve been a customer, contract, payment method, paperless billing, monthly charges, and total charges
- Demographic info about customers – gender, age range, and if they have partners and dependents

####The goal
is to create an app which would predict whether the customer is likely to leave
The data processing is done only in a pipeline. Missing or incorrect data is
filled with median (for quantitative traits) / mode (for categorical traits)

#### Задача:

создать приложение, которое будет выдавать ответ, склонен ли запрашиваемый покупатель (покупатели) уйти в отток. 
Подразумевается, что можно ввести неправильные данные или незнакомый для предобученной модели категориальный признак, задача по этим данным сделать прогноз. 

Обработка данных происходит только в рамках пайплайна. Отсутствующие/ошибочные данные в количественных признаках заполняются медианой, в категориальных - модой  

#### Clone repository and create project

Use the Docker command line

$ git clone https://github.com/YanaAbakumova/Projects/Customer_Churn_Prediction
$ cd Customer_Churn_Prediction
$ docker build -t Customer_Churn_Prediction .


Run docker

$ docker run -d -p 8080:8080 Customer_Churn_Prediction

Go to http://localhost:8080 or http://127.0.0.1:8080/