//MQTTbroker.h
/*description of the message structure and the inscription of various node to different topics*/

#ifndef MQTT_H
#define MQTT_H

typedef nx_struct node_message_t 
{
	nx_uint8_t msg_topic; // TEMP HUM LUM
	nx_uint8_t msg_type; //ReqConn-ReqSub ...
	nx_uint16_t msg_id; 
	nx_uint16_t value; //value to publish
	nx_uint16_t QoS;
} node_message_t;

enum
{
	ReqConn = 0, ReqSub = 1, ReqPub = 2, RespPub = 3, Fwd = 4
};

enum
{
	TIMER_SIZE = 1000,
	broker = 8,
	TEMP = 0, HUM = 1, LUM = 2
};

bool reg_temp [broker]={FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE};
bool reg_hum [broker]={FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE};
bool reg_lum [broker]={FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE};
uint16_t required_QoS [broker]={0,0,0,0,0,0,0,0};
uint16_t read_data=0; //salvataggio lettura dato da read

#endif


 


