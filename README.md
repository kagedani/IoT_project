# IoT project: lightweight publish-subscribe application protocol

It is required to design and implement an application protocol of publication-registration similar to the MQTT and test it on a topology composed of 8 nodes and PAN coordinator acting as a MQTT broker.

## Functions 

The following functions were required: 
1. CONNECTION: once the structure is activated, each node sends a message to CONNECT to PAN coordinator, which responds with a message from CONNACK.
2. SUBSCRIBE: each node can subscribe to three topics [TEMPERATURE, HUMIDITY and BRIGHTNESS].
To subscribe to these topics, the node sends a SUBSCRIBE message with its own ID, the topic to which it requires to register and the QoS; the SUBSCRIBE message receives a response from registration from the PAN coordinator via the SUBACK message. [In our case we have also implemented multiple sign-up to multiple topics, 3 nodes subscribe to two topics each]
3. PUBLISH: the public node the value read by the sensor to the PAN coordinator that will forward the
message to the nodes that are subscribed to the message topic. [In our case we have
implemented only one node that publishes the values]
4. Management of QoS: in the PUBLISH message we have two levels of QoS:
- 0 = the node transmits the message only once.
- 1 = the node continues to retransmit until the PAN coordinator answers with a
message of PUBACK

In our simulation we used the TOSSIM simulation environment.

### Instruction to execute

In the folder there are all the file for the execution.
The file named ReportMQTTbroker.pdf describes the project and what we had implemented.
The file log.txt is the print of the execution of the program.
