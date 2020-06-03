#include <Arduino.h>
#include "heltec.h"
#include "main.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include <WiFi.h>
#include <AWS_IOT.h>
#include <ArduinoJson.h>
#include <HTTPClient.h>

void setup(){

    xQueue_data_from_AWS = xQueueCreate(1 , sizeof(char[57]));

    Heltec.display->init();   
    Heltec.display->flipScreenVertically();
    Heltec.display->setFont(ArialMT_Plain_10);
    Heltec.display->drawString(0, 0, "thingsCortex - IoT and AI");
    Heltec.display->drawString(0, 10, "Sensor ID: cortex0");
    Heltec.display->drawString(0, 20, "Asset: Pump A");
    Heltec.display->display();

    Serial.begin(BAUD_RATE);
    delay(2000);

    Heltec.display->drawString(0, 40, "Connecting to WiFi...");
    Heltec.display->display();

    int status = WL_IDLE_STATUS;
    while (status != WL_CONNECTED)
    {
        Serial.print("Attempting to connect to SSID: ");
        Serial.println(ssid);
        // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
        status = WiFi.begin(ssid, password);
        // wait 5 seconds for connection:
        delay(5000);
    }
    Serial.print("Connected to WiFi. IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("Gateway IP: ");
    Serial.println(WiFi.gatewayIP());
    Heltec.display->clear();
    Heltec.display->drawString(0, 0, "Connected to WiFi");
    Heltec.display->drawString(0, 10, "IP: ");
    Heltec.display->drawString(60, 10, WiFi.localIP().toString());
    Heltec.display->drawString(0, 20, "Gateway: ");
    Heltec.display->drawString(60, 20, WiFi.gatewayIP().toString());
    Heltec.display->drawString(0, 30, "Connecting to AWS...");
    Heltec.display->display();

    // xTaskCreatePinnedToCore(&Send_Data_LAMP_Server, "POST to LAMP Server", 9600, NULL, 1, NULL, 0);
    AWS_CONNECTION_ATTEMPT_t status_attempt_connection_aws;

    status_attempt_connection_aws = Attempt_Connection_AWS();

    if( status_attempt_connection_aws == UNSUCEEDED ){
        abort();
    }
    else if( status_attempt_connection_aws == SUCCEEDED ){

        // xQueue_data_from_AWS = xQueueCreate(1 , sizeof(char[57]));
        if( xQueue_data_from_AWS != NULL ){

            Serial.println("Queue created");
            xTaskCreatePinnedToCore(&Send_Data_LAMP_Server, "POST to LAMP Server", 2000, NULL, 1, NULL, 0);       
        }
        else{
            Serial.println("Could not create Queue");
            abort();
        }
    }

}

void loop(){

}

AWS_CONNECTION_ATTEMPT_t Attempt_Connection_AWS(void){

    AWS_IOT aws_iot;

    if (aws_iot.connect(aws_mqtt_server, aws_mqtt_client_id) == 0)
    {
        Serial.println("Connected to AWS");
        Heltec.display->drawString(0, 40, "Connected to AWS");
        Heltec.display->display();
        delay(2000);

        if(0==aws_iot.subscribe(aws_mqtt_thing_topic_pub, Subscribe_Callback_Handler))
        { 
            Serial.println("Subscribe Successfull");
            Heltec.display->clear();
            Heltec.display->drawString(0, 0, "Listening to topic");
            Heltec.display->display();
            delay(1000);
            return SUCCEEDED;
        }
        else
        {
            Serial.println("Subscribe Failed. Check the Thing Name and Certificates");
            Heltec.display->clear();
            Heltec.display->drawString(0, 0, "Could not subscribe to topic");
            Heltec.display->display();
            return UNSUCEEDED;
        }
    }
    else
    {
        Serial.println("AWS connection failed. Check the HOST Address");
        Heltec.display->clear();
        Heltec.display->drawString(0, 0, "Could not connect to AWS");
        Heltec.display->display();
        return UNSUCEEDED;
    }

}

void Subscribe_Callback_Handler(char *topicName, int payloadLen, char *payLoad)
{
    // char rcvdPayload[100];
    char json[100];
    BaseType_t xStatus;
    
    // strncpy(rcvdPayload,payLoad,payloadLen);
    // rcvdPayload[payloadLen] = 0;
    strncpy(json, payLoad, payloadLen);
    json[payloadLen] = 0;

    StaticJsonBuffer<100> jsonBuffer;
    JsonObject &object = jsonBuffer.parseObject(json);
    const char* values[3] = {object["pressure"], object["flowRate"], object["tankLevel"]};
    Heltec.display->clear();
    Heltec.display->drawString(0, 0, "Pressure (bar): ");
    Heltec.display->drawString(90, 0, values[0]);
    Heltec.display->drawString(0, 20, "Flow Rate (L/m): ");
    Heltec.display->drawString(90, 20, values[1]);   
    Heltec.display->drawString(0, 40, "Tank Level (%): ");
    Heltec.display->drawString(90, 40, values[2]);
    Heltec.display->display();

    // char * test = "{\"pressure\": 107.4,\"flowRate\": 30.91,\"tankLevel\": 92.65}";
    xStatus = xQueueSendToBack( xQueue_data_from_AWS, payLoad, 0 );
    if( xStatus == pdPASS ){
        Serial.println("Queue sent");        
    }
    else{
        Serial.println("Queue not sent");
    }
}

void Send_Data_LAMP_Server(void *pvParameters){

    char json_received_from_queue[60];
    // // char test[70];
    
    BaseType_t xStatus;

    char message[100];
    sprintf(message, "Stack remaining for task '%s' is %d bytes", pcTaskGetTaskName(NULL), uxTaskGetStackHighWaterMark(NULL));
    Serial.println(message);

    //  TickType_t xTicksToWait = 5000 / portTICK_RATE_MS;

    int count = 0;

    for(;;){

        xStatus = xQueueReceive( xQueue_data_from_AWS, json_received_from_queue, portMAX_DELAY );
        if( xStatus == pdPASS ){

        // Serial.println(json_received_from_queue);   
        // count++;
        // Serial.print("Counter ");
        // Serial.println(count);
                HTTPClient http;
                http.begin(serverName);
                http.addHeader("Content-Type", "application/x-www-form-urlencoded");
                int httpResponseCode;
        
                Serial.println("Queue received successfully");
                StaticJsonBuffer<60> jsonBuffer;
                JsonObject& object = jsonBuffer.parseObject(json_received_from_queue);
                const char* values[3] = {object["pressure"], object["flowRate"], object["tankLevel"]};

                

                String httpRequestData = "api_key=" + apiKeyValue + "&sensor=" + "cortex0"
                                        + "&location=" + sensorLocation + "&pressure=" + String(values[0])
                                        + "&flowRate=" + String(values[1]) + "&tankLevel=" + String(values[2]) + "";

                // Serial.println(values[0]);
                // Serial.println(values[1]);
                // Serial.println(values[2]);

                httpResponseCode = http.POST(httpRequestData);

                Serial.print("httpRequestData: ");
                Serial.println(httpRequestData);

                if (httpResponseCode>0) {
                    Serial.print("HTTP Response code: ");
                    Serial.println(httpResponseCode);
                }//if (httpResponseCode>0)
                else {
                    Serial.print("Error code: ");
                    Serial.println(httpResponseCode);
                }

                http.end();
            
            }//if( xStatus == pdPASS )
            else{
                Serial.println("Queue not received");
            }
    }
}