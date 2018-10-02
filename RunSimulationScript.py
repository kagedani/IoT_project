print "********************************************";
print "*                                          *";
print "*             TOSSIM Script                *";
print "*                                          *";
print "********************************************";

import sys;
import time;


from TOSSIM import *;

t = Tossim([]);

#connections among nodes
topofile="Topology.txt"; 

#Link radio
modelfile="meyer-heavy.txt"; 

print "Initialization of mac...";
mac = t.mac();
print "Initialization of radio channels....";
radio = t.radio();
print "Topology used:",topofile;
print "Noise used:",modelfile;

print "Initialization of simulator....";
t.init(); 

out = sys.stdout;

#Add debug,radio channel
print "Activate debug message on channel radio"
t.addChannel("radio",out);

#Create 8 sensors + 1 broker
node = [];
for i in range (0,9):
	print "Creating node ",i;
	node.append(t.getNode(i));
	time = (9-i)*t.ticksPerSecond();
	node[i].bootAtTime(time);
	print ">>>This node is starting at ",  time/t.ticksPerSecond(), "[sec]";

print "Creating radio channels..."
f = open(topofile, "r");
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    print ">>>Setting radio channel from node ", s[0], " to node ", s[1]," with gain ", s[2], " dBm";
    radio.add(int(s[0]), int(s[1]),float(s[2]))

#Creazione del modello di canale

print "Initializing Closest Pattern Matching (CPM)...";
noise = open(modelfile, "r")
lines = noise.readlines()
compl = 0;
mid_compl = 0;

#Lettura dati dal file del modello di rumore
print "Reading noise model data file:", modelfile;
print "Loading:",
for line in lines:
    str = line.strip()
    if (str != "") and ( compl < 10000 ):
        val = int(str)
        mid_compl = mid_compl + 1;
        if ( mid_compl > 5000 ):
            compl = compl + mid_compl;
            mid_compl = 0;
            sys.stdout.write ("#")
            sys.stdout.flush()
        for i in range(0, 9):
            t.getNode(i).addNoiseTraceReading(val)
print "Done!";

#modello di rumore per ogni nodo
for i in range(0, 9):
    print ">>>Creating noise model for node:",i;
    t.getNode(i).createNoiseModel()

print "Start simulation with TOSSIM! \n\n\n";

for i in range(0,30000):
	t.runNextEvent()
	
print "\n\n\nSIMULATION DONE!";

