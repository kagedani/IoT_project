/**
 *  Configuration file for wiring of ReadingSensorP module to other common 
 *  components to simulate the behavior of a real sensor
 *
 *  @author Luca Pietro Borsani
 */
 
generic configuration ReadingSensorC() {

	provides interface Read<uint16_t>;

} implementation {

	components MainC, RandomC;
	components new ReadingSensorP();
	components new TimerMilliC();
	
	//Connects the provided interface
	Read = ReadingSensorP;
	
	//Random interface and its initialization	
	ReadingSensorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;
	
	//Timer interface	
	ReadingSensorP.Timer0 -> TimerMilliC;

}
