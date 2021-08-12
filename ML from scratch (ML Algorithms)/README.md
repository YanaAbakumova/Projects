## "ML Algorithms" course project at Geekbrains

The goal is to create ML models from scratch and use them in classification
and regression projects.

Задача написать код моделей машинного обучения "с нуля" и использовать эти
модели в регрессионной и классификационной задачах.

#### Rules: You can only use these imports:

import numpy as np

import pandas as pd

from sklearn.model_selection import train_test_split

import matplotlib.pyplot as plt

import seaborn as sns


###  Regression:Tutors - expected math exam results
Predict average math exam results for students of the tutors - https://www.kaggle.com/c/tutors-expected-math-exam-results

#### Dataset description:

    Id - идентификационный номер
    age - возраст
    years_of_experience - стаж
    lesson_price - цена урока
    qualification – квалификация
    physics – физика
    chemistry – химия
    biology – биология
    english – английский
    geography – география
    history – история
    mean_exam_points (target variable)– средний балл

#### Metrics: R2-score
#### Result (public leaderboard): 0.78451



###  Classification: Choose proper tutors for math exam

In this competition your task will be to predict the probability for a
 tutor to be a proper one for preparing for the math exam. - 
 https://www.kaggle.com/c/choose-tutors

#### Dataset description:

    Id - идентификационный номер
    age - возраст
    years_of_experience - стаж
    lesson_price - цена урока
    qualification – квалификация
    physics – физика
    chemistry – химия
    biology – биология
    english – английский
    geography – география
    history – история
    mean_exam_points – средний балл
    choose (target variable)- подходящий репетитор

#### Metrics: ROC_AUC
#### Result (public leaderboard): 0.85287