import numpy as np
import dill
import pandas as pd
import os

dill._dill._reverse_typemap['ClassType'] = type
# import cloudpickle
import flask

# initialize our Flask application and the model
app = flask.Flask(__name__)
model = None


def load_model(model_path):
    # load the pre-trained model
    global model
    with open(model_path, 'rb') as f:
        model = dill.load(f)


@app.route("/", methods=["GET"])
def general():
    return "Welcome to churn prediction"


@app.route("/predict", methods=["POST"])
def predict():
    # initialize the data dictionary that will be returned from the
    # view
    data = {"success": False}

    # ensure an image was properly uploaded to our endpoint
    #if flask.request.method == "POST":
        #customerID, gender, SeniorCitizen, Partner, Dependents, tenure, PhoneService, MultipleLines, \
        #InternetService, OnlineSecurity, OnlineBackup, DeviceProtection, TechSupport, StreamingTV, StreamingMovies,\
        #Contract, PaperlessBilling, PaymentMethod, MonthlyCharges, TotalCharges = \
            #'8879-ZKJOF', 'Female', 0, 'No', 'No', 41, 'Yes', 'No', 'DSL', 'Yes', 'No',\
            #'Yes', 'Yes', 'Yes', 'Yes', 'One year', 'Yes', 'Bank transfer (automatic)', 79.85, 3320.75
    request_json = flask.request.get_json()
    #if request_json["customerID"]:
    customerID = request_json['customerID']
    #if request_json["gender"]:
    gender = request_json['gender']
    #if request_json["SeniorCitizen"]:
    SeniorCitizen = request_json['SeniorCitizen']
    #if request_json["Partner"]:
    Partner = request_json['Partner']
    #if request_json["Dependents"]:
    Dependents = request_json['Dependents']
    #if request_json["tenure"]:
    tenure = request_json['tenure']
    #if request_json["PhoneService"]:
    PhoneService = request_json['PhoneService']
    #if request_json["MultipleLines"]:
    MultipleLines = request_json['MultipleLines']
    #if request_json["InternetService"]:
    InternetService = request_json['InternetService']
    #if request_json["OnlineSecurity"]:
    OnlineSecurity = request_json['OnlineSecurity']
    #if request_json["OnlineBackup"]:
    OnlineBackup = request_json['OnlineBackup']
    #if request_json["DeviceProtection"]:
    DeviceProtection = request_json['DeviceProtection']
    #if request_json["TechSupport"]:
    TechSupport = request_json['TechSupport']
    #if request_json["StreamingTV"]:
    StreamingTV = request_json['StreamingTV']
    #if request_json["StreamingMovies"]:
    StreamingMovies = request_json['StreamingMovies']
    #if request_json["Contract"]:
    Contract = request_json['Contract']
    #if request_json["PaperlessBilling"]:
    PaperlessBilling = request_json['PaperlessBilling']
    #if request_json["PaymentMethod"]:
    PaymentMethod = request_json['PaymentMethod']
    #if request_json["MonthlyCharges"]:
    MonthlyCharges = request_json['MonthlyCharges']
    #if request_json["TotalCharges"]:
    TotalCharges = request_json['TotalCharges']

    preds = model.predict_proba(pd.DataFrame({'customerID': [customerID],
                                          'gender': [gender],
                                          'SeniorCitizen': [SeniorCitizen],
                                          'Partner': [Partner],
                                          'Dependents': [Dependents],
                                          'tenure': [tenure],
                                          'PhoneService': [PhoneService],
                                          'MultipleLines': [MultipleLines],
                                          'InternetService': [InternetService],
                                          'OnlineSecurity': [OnlineSecurity],
                                          'OnlineBackup': [OnlineBackup],
                                          'DeviceProtection': [DeviceProtection],
                                          'TechSupport': [TechSupport],
                                          'StreamingTV': [StreamingTV],
                                          'StreamingMovies': [StreamingMovies],
                                          'Contract': [Contract],
                                          'PaperlessBilling': [PaperlessBilling],
                                          'PaymentMethod': [PaymentMethod],
                                          'MonthlyCharges': [MonthlyCharges],
                                          'TotalCharges': [TotalCharges]
                                          }))
    data["predictions"] = preds[:, 1][0]
    # Best Threshold=0.366063 (рассчитан на шаге 1)
    thr = 0.366063
    if preds[:, 1][0] > thr:
        data['forecast'] = 'клиент может уйти в отток!'
    else:
        data['forecast'] = 'с клиентом всё хорошо.'

    data["customerID"] = customerID
    # indicate that the request was a success
    data["success"] = True

    # return the data dictionary as a JSON response
    return flask.jsonify(data)

# if this is the main thread of execution first load the model and
# then start the server
if __name__ == "__main__":
    print(("* Loading the model and Flask starting server..."
           "please wait until server has fully started"))
    modelpath = "/app/app/models/catboost_pipeline.dill"
    load_model(modelpath)
    port = int(os.environ.get('PORT', 8180))
    app.run(host='0.0.0.0', debug=True, port=port)

