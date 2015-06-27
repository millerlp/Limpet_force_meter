

int tstep = 500;
int oldtime = 0;
int aVal0 = 0;
int aVal1 = 0;
int aVal2 = 0;
int aVal3 = 0;
int aVal4 = 0;
int aVal5 = 0;

void setup(){
	Serial.begin(57600);
	Serial.println("Hello");
	
	analogReadResolution(12); //read-in analog inputs as 12 bit
	
	delay(200);
	oldtime = millis();
	
}

void loop(){
	if (millis() > oldtime + tstep){
		aVal0 = analogRead(0); // read channel 0
		aVal1 = analogRead(1); // read channel 1
		aVal2 = analogRead(2); // read channel 2
		aVal3 = analogRead(3); // read channel 3
		aVal4 = analogRead(4); // read channel 4
		aVal5 = analogRead(5); // read channel 5
		delay(1);
		Serial.print(aVal0);
		Serial.print("\t");
		Serial.print(aVal1);
		Serial.print("\t");
		Serial.print(aVal2);
		Serial.print("\t");
		Serial.print(aVal3);
		Serial.print("\t");
		Serial.print(aVal4);
		Serial.print("\t");
		Serial.print(aVal5);
		Serial.println();
	}
}