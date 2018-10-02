#include "MQTTbroker.h"

configuration MQTTbrokerAppC {}

implementation 
{
  components MainC, MQTTbrokerC as App;
  components new AMSenderC (broker) as manage_sub;
  components new AMSenderC (broker) as manage_conn;
  components new AMSenderC (broker) as manage_reqpub;
  components new AMSenderC (broker) as manage_pub;
  components new AMSenderC (broker) as manage_fwd;
  components new AMReceiverC(broker);
  components ActiveMessageC; 
  components new TimerMilliC();
  components new ReadingSensorC();
  components RandomC;

 //Boot interface
  App.Boot -> MainC.Boot;

  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.manage_sub -> manage_sub;
  App.manage_conn -> manage_conn;
  App.manage_reqpub -> manage_reqpub;
  App.manage_pub -> manage_pub;
  App.manage_fwd -> manage_fwd;

  //Radio Control
  App.AMControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> manage_conn;
  App.Packet -> manage_conn;
  App.Packet -> manage_sub;
  App.Packet -> manage_reqpub;
  App.Packet -> manage_pub;
  App.Packet -> manage_fwd;
  App.PacketAck->ActiveMessageC;

  //Timer interface
  App.Cntdwn -> TimerMilliC;

  //Reading Sensor read
  App.Read -> ReadingSensorC;

  //Random interface for QoS
  App.Random -> RandomC;

}
