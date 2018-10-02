/**
 *  Source file for implementation of module Middleware
 *  which provides the main logic for middleware message management
 *
 *  @author Luca Pietro Borsani
 */
 
generic module ReadingSensorP() {

	provides interface Read<uint16_t>;
	
	uses interface Random;
	uses interface Timer<TMilli> as Timer0;

} implementation {

	uint8_t value;
	//***************** Boot interface ********************//
	command error_t Read.read(){
		dbg("radio","Start timer for sampling data.\n");
		call Timer0.startOneShot(10);
		return SUCCESS;
	}

	//***************** Timer0 interface ********************//
	event void Timer0.fired() {
		dbg("radio","Timer fired.\n");
		value = 1+(call Random.rand16())%70;
		signal Read.readDone(SUCCESS, value);
	}
}
