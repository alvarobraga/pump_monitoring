#ifndef MAIN_H

QueueHandle_t xQueue_data_from_AWS;
TaskHandle_t * connect_to_wifi_task_handle;

#define BAUD_RATE 9600
#define EVENT_WIFI_CONNECTED ( 1UL << 0UL )
#define EVENT_STEP1 1UL



/*Wifi Details*/
const char *ssid = "Belong4FB194";
const char *password = "j3xtztmpcwcd";
/*AWS MQTT Details*/
const char * thing_id = "thingsCortex";
char *aws_mqtt_server = "a2upasvvjnl6z1-ats.iot.us-east-1.amazonaws.com";
char *aws_mqtt_client_id = "thingsCortex";
char *aws_mqtt_thing_topic_pub = "test_topic/esp32";
/*LAMP Server details*/
const char* serverName = "http://10.0.0.12/post-esp-data.php";
String apiKeyValue = "tPmAT5Ab3j7F9";
String sensorLocation = "Pump A";



typedef enum {
    SUCCEEDED,
    UNSUCEEDED
} AWS_CONNECTION_ATTEMPT_t;

AWS_CONNECTION_ATTEMPT_t Attempt_Connection_AWS(void);
void Subscribe_Callback_Handler(char *topicName, int payloadLen, char *payLoad);
void Send_Data_LAMP_Server(void *pvParameters);

#endif