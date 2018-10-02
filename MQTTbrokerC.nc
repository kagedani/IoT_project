//MQTTbrokerC.nc

#include "MQTTbroker.h"
#include "Timer.h"
#include "TinyError.h"



module MQTTbrokerC 
{
	uses
	{
		interface Boot;	
		interface Packet;
		interface AMPacket;
		interface AMSend as manage_conn;
		interface AMSend as manage_sub;
		interface AMSend as manage_fwd;
		interface AMSend as manage_reqpub;
		interface AMSend as manage_pub;
		interface PacketAcknowledgements as PacketAck;
		interface Receive;
		interface SplitControl as AMControl;
		interface Timer<TMilli> as Cntdwn;
		interface Read<uint16_t>;
		interface Random;
	}
}

implementation
{
	
	uint8_t counter = 0; /*counter for id of messages*/
	uint8_t received_id = 0;
	uint8_t info = 0;
	uint8_t k = 0;
	uint8_t locked = 0;
	uint8_t flag = 0;
	message_t packet;
	message_t dataPacket;
	task void nodeReqConn();
  	task void nodeReqSub();
  	task void nodeReqPub();
  	task void pubToBroker();
  	task void forward();

/*Program booting*/
event void Boot.booted() 
	{
		call AMControl.start();  	
		
	}

/*AMControl interface
	initializes every single node*/

event void AMControl.startDone(error_t err)
	{
		if(err == SUCCESS) 
		{
			if(TOS_NODE_ID != broker)
			{
				//dbg("radio","Timer of %d started at time: %s\n", TOS_NODE_ID, sim_time_string());
				call Cntdwn.startPeriodic(TIMER_SIZE+(TOS_NODE_ID)*100);
			}
			else
			{
				dbg("radio","Broker has been turned on.\n\tReady to receive connection requests.\n");
			}
		}
		else
		{
			//dbg("radio","#####REBOOT#####\n");
			call AMControl.start();
		}
	}
    
event void AMControl.stopDone(error_t err){}

		
/*Cntdwn interface
	when the timer fired each node start requesting the connection to the broker*/

event void Cntdwn.fired() 
	{
		dbg("radio","Timer fired at time: %s, re-asking for connection!\n", sim_time_string());
		if(locked==0)
		{
			post nodeReqConn();	
		}
		
	}

/*Request of connection sent by every node to the broker*/

task void nodeReqConn()
{

		node_message_t* conn_message = (node_message_t*) (call Packet.getPayload(&packet,sizeof(node_message_t)));
		conn_message -> msg_type = ReqConn;
		counter = counter+1;
		conn_message -> msg_id = counter;
		call PacketAck.requestAck(&packet);
	
	if(call manage_conn.send(broker,&packet,sizeof(node_message_t)) == SUCCESS)
	{
		locked=1;
		//dbg("radio","Packet sent.\nSource: %hhu\tDestination: %hhu\tID: %d\n",call AMPacket.source(&packet), call AMPacket.destination(&packet),conn_message->msg_id);
	}
	
}

/*SendDone event: connection manager*/
event void manage_conn.sendDone(message_t* buf, error_t err)
{	
	if(&packet == buf && err == SUCCESS)
	{
		locked=0;
		if(call PacketAck.wasAcked(buf))	
		{
			dbg("radio","Connection manager: my packet has been received, I'm asking for subscription...\n",TOS_NODE_ID);
			call Cntdwn.stop();
			post nodeReqSub();
		}
		else
		{
			post nodeReqConn();
		}
	}
}

/*Request for Subscription*/
task void nodeReqSub()
{
	node_message_t* sub_message = (node_message_t*) (call Packet.getPayload(&packet,sizeof(node_message_t)));
	sub_message -> msg_type = ReqSub;
	sub_message -> msg_id = counter+1;
	sub_message -> QoS = (call Random.rand16())%2;

	dbg("radio","Asking for subscription...\n");

	if(TOS_NODE_ID == 0 || TOS_NODE_ID == 7)
	{ 
		if(TOS_NODE_ID == 7)
		{
			sub_message -> msg_topic = TEMP;
		}
		else
		{
			if(reg_temp[TOS_NODE_ID] == TRUE)
			{
				sub_message -> msg_topic = HUM;
				sub_message -> QoS = required_QoS[TOS_NODE_ID];
			}
			else
			{
				sub_message -> msg_topic = TEMP;
			}
		}
	}
	else if(TOS_NODE_ID == 1 || TOS_NODE_ID == 6)
	{	
		if(TOS_NODE_ID == 6)
		{
			sub_message -> msg_topic = HUM;
		}
		else
		{
			if(reg_hum[TOS_NODE_ID] == TRUE)
			{
				sub_message -> msg_topic = TEMP;
				sub_message -> QoS = required_QoS[TOS_NODE_ID];
			}
			else
			{
				sub_message -> msg_topic = HUM;
			}
		}
	}
	else 
	{
		if(TOS_NODE_ID != 3)
		{
			sub_message -> msg_topic = LUM;
		}
		else
		{
			if(reg_lum[TOS_NODE_ID] == TRUE)
			{
				sub_message -> msg_topic = HUM;
				sub_message -> QoS = required_QoS[TOS_NODE_ID];
			}
			else
			{
				sub_message -> msg_topic = LUM;
			}
		}
	}
	call PacketAck.requestAck(&packet);

	if(call manage_sub.send(broker, &packet, sizeof(node_message_t))== SUCCESS)
	{
		dbg("radio","Subscribed with success.\n");
		dbg("radio","TOPIC %hhu\n",sub_message->msg_topic);
		dbg("radio","QoS %hhu\n",sub_message->QoS);
		dbg("radio","SORGENTE %hhu\n",call AMPacket.source(&packet));
	}
}

/*SendDone event: subscription event*/
event void manage_sub.sendDone(message_t* buf, error_t outcome)
{	
	if(&packet == buf && outcome == SUCCESS)
		{
			if(call PacketAck.wasAcked(buf))
			{	
				node_message_t* extract_info = (node_message_t*) (call Packet.getPayload(&packet,sizeof(node_message_t)));
				//dbg("radio","Subscription manager: packet acked.\n");
				required_QoS[TOS_NODE_ID]= extract_info->QoS;
				if(TOS_NODE_ID == 0 || TOS_NODE_ID == 7)
				{ 
					if(extract_info -> msg_topic == TEMP)
					{
						reg_temp[TOS_NODE_ID]=TRUE;

						if(TOS_NODE_ID == 0 && reg_hum[TOS_NODE_ID] == FALSE)
						{
							dbg("radio","I'm subscribing to another topic.\n");
							post nodeReqSub();
						}
					}
					else	
					{
						reg_hum[TOS_NODE_ID] = TRUE;
						post nodeReqPub();
				/*node 0 request for publishing on humidity topic*/
					}
				}
				else if(TOS_NODE_ID == 1 || TOS_NODE_ID == 6)
				{	
					if(extract_info -> msg_topic == HUM)
					{
						reg_hum[TOS_NODE_ID]=TRUE;
						if(TOS_NODE_ID == 1 && reg_temp[TOS_NODE_ID] == FALSE)
						{
							dbg("radio","I'm subscribing to another topic.\n");
							post nodeReqSub();
						}
					}
					else
					{
						reg_temp[TOS_NODE_ID] = TRUE;
					}
				}
				else
				{
					if(extract_info -> msg_topic == LUM)
					{
						reg_lum[TOS_NODE_ID]=TRUE;
						if(TOS_NODE_ID == 3 && reg_hum[TOS_NODE_ID] == FALSE)
						{
							dbg("radio","I'm subscribing to another topic.\n");
							post nodeReqSub();
						}
					}
					else
					{
						reg_hum[TOS_NODE_ID] = TRUE;
					}
				}
			
			}
			else
			{
				dbg("radio","Subscription manager: packet not acked.\n");
				post nodeReqSub();
			}
		}
		else
		{
			dbg("radio","Subscription manager: packet lost.\n");
			post nodeReqSub();
		}
}


/*Request to publish event
		one of the node connected to the broker is in charge to publish about a specific topic
		but before it needs to ask the broker the 'permission'*/
task void nodeReqPub ()
{
		node_message_t* reqPub_message = (node_message_t*) (call Packet.getPayload(&packet,sizeof(node_message_t)));
		reqPub_message -> msg_type = ReqPub;
		reqPub_message -> msg_id = counter+1;
		call PacketAck.requestAck( &packet ); 
		if(call manage_reqpub.send(broker,&packet,sizeof(node_message_t)) == SUCCESS)
		{
			dbg_clear("radio","##############################\n");
			dbg("radio","Request to publish: success!\n");
			dbg("radio","TOPIC: %hhu\n",reqPub_message->msg_topic);
			dbg("radio","SORGENTE %hhu\n",call AMPacket.source(&packet));
			dbg_clear("radio","##############################\n");
		}
}

/*SendDone event: publish manager*/
event void manage_reqpub.sendDone(message_t* buf, error_t outcome)
{
	if(&packet == buf && outcome == SUCCESS)
	{
		if (call PacketAck.wasAcked(&packet))
		{
			dbg("radio","Request to publish acked: starting to sample data.\n");
			post pubToBroker();
		}
		else
		{
			dbg("radio","Request for publication not acked.\n");
			post nodeReqPub();
		}
	}
	else
	{	
		dbg("radio","Problem with sending phase: request to publish task.\n");
		post nodeReqPub(); 
	//if the sending event have encountered some troubles another request is sent
	}
}

/*Reading value to send to the broker*/
task void pubToBroker()
{
	call Read.read();
}	

/*ReadDone event: send the packet to the broker with the value*/
event void Read.readDone(error_t outcome, uint16_t value)
{
	node_message_t* toPub=(node_message_t*)(call Packet.getPayload(&packet,sizeof(node_message_t*)));
	toPub->msg_type = RespPub;
	toPub->msg_id = received_id;
	toPub->value = value;
	read_data = value;
	dbg("radio", "Data read: %hhu\n", read_data);
	call PacketAck.requestAck(&packet); 
	if(call manage_pub.send(broker,&packet,sizeof(node_message_t)) == SUCCESS)
	{
		dbg("radio","Data sent to the broker for publication.\n");
	}
	else
	{
		dbg("radio","Problem with sending phase: trying to republish.\n");
		post pubToBroker();
	}
}

/*SendDone event: publish manager*/
event void manage_pub.sendDone(message_t* buf, error_t outcome)
{
	if(&packet == buf && outcome == SUCCESS)
	{
		if (call PacketAck.wasAcked(&packet))
		{
			dbg("radio","Packet with data to forward acked.\n");
		}
		else
		{
			if(required_QoS[call AMPacket.source(&packet)] == 1)
			{
				dbg("radio","Packet not acked but with QoS = 1: re-asking for pubblication.\n");
				post pubToBroker();
			}
			else 
				dbg("radio","Packet not acked with QoS = 0: lost.\n");
		/*if QoS is equal to 0, in any case the packet, if received by the broker is forwarded*/
		}
	}
	else
	{	
		dbg("radio","Problem with sending phase.\n");
		post pubToBroker(); 
	//if the sending event have encountered some troubles another request is sent
	}
}


/*Receive packet broker interface*/
event message_t* Receive.receive(message_t* bufpub,void* payload, uint8_t len)
{
	node_message_t* Br_msg=(node_message_t*)payload;
	received_id = Br_msg->msg_id; 
	if (TOS_NODE_ID == broker)
	{
		if(Br_msg -> msg_type == RespPub){
			dbg("radio", "Packet received successfully with value: %hhu\nReady to forward the packet.\n",Br_msg->value);
			dbg_clear("radio", "SOURCE: %hhu\nTOPIC: %hhu\nVALUE: %hhu\nTYPE: %hhu\n",call AMPacket.source(&packet), Br_msg -> msg_topic, Br_msg -> value, Br_msg -> msg_type);
			post forward();
		}
	}
	return bufpub;
}

/*Forwarding task*/
task void forward()
{
	info = read_data;
	if(k>=0 && k<broker)
	{
		if(flag == 1)
		{
			dbg("radio","Forwarding failed in previous attempt, trying again.\n");
			k--;
			flag = 0;
		}
		dbg_clear("radio","############################\nForwarding task.\t\t\t\ttime: %d\n############################\n", k);
		dbg("radio","Node %d, checking registration.\n",k);
		if(reg_hum[k] == TRUE && k != (call AMPacket.source(&dataPacket)))
		{
			node_message_t* notification =(node_message_t*)(call Packet.getPayload(&dataPacket,sizeof(node_message_t))); 
			notification->msg_type = Fwd;
			notification->msg_id = received_id;
			notification->value = info;
			call PacketAck.requestAck(&dataPacket); 
			if(call manage_fwd.send(k, &dataPacket, sizeof(node_message_t)))
			{
				dbg("radio","Forwarding: success!\n");
				dbg("radio","DESTINATION: %hhu\n",call AMPacket.destination(&dataPacket));
				dbg("radio","SOURCE: %hhu\n",call AMPacket.source(&dataPacket));
				dbg("radio","Value: %hhu\n", notification->value);
			/*if the sending phase has troubles, the packet needs to be re-sent to the same node of this round of the for-cycle*/
			}
			else
			{
				dbg("radio","Failed forward.\n");
				flag = 1;
				k++;
				post forward();
			}
		}
		else
		{
			if(k == (call AMPacket.source(&dataPacket)))
			{
				dbg("radio","Node %d is the one publishing, no need to forward him the message.\n");
			}
			else
				dbg("radio","Node %d, not registered.\n",k);
			if(k<=6)
			{
				k++;
				post forward();
			}
			else
			{
				dbg("radio","Forwarded to all subscribed nodes.\n");
			}
		}
		
	}
}
/*
/*SendDone event: forwarding manager*/
event void manage_fwd.sendDone(message_t* buf, error_t outcome)
{
	if(&dataPacket == buf && outcome == SUCCESS)
	{	
		if(call PacketAck.wasAcked(&dataPacket))
		{
			dbg_clear("radio","############################\n");
			dbg("radio","Packet forwarded and acked.\n");
			dbg("radio","DESTINATION: %hhu\n",call AMPacket.destination(&dataPacket));
			dbg_clear("radio","############################\n");
		}
		else
		{
			dbg("radio","Packet forwarded but not acked: %hhu.\n", call AMPacket.destination(&dataPacket));
		}
	}
	else
	{
		dbg("radio","Problem with forwarding event.\n");	
	}
	k++;
	post forward();
}

}

