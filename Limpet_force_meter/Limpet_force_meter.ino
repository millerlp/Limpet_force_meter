/* Limpet_force_meter.ino

      Last edit: 2015 07 03 LPM
      
      Software to run one joystick force transducer and associated cantilever force transducer on 
      battery power to measure forces of oystercatcher predatory strike on a model limpet. 
      
      Burst samples at a rate set by SAMPLE_INTERVAL_MS for SAMPLE_LEN milliseconds then pauses to
      write to card. Opens a file then repeats burst sampling, going through FILE_CYCLES_TOT number 
      of cycles before closing current file and then opening a new one. 
      Output filename is in the format YYYYMMDD_HHMM_xx.csv where xx is a counter from
      0-99 to avoid filename collisions. 
      
      
      Designed to burst sample at 100Hz and make single files of 5 min length each.
      
      
      Components:
        Arduino DUE
        Associated limpet forcemeter circuit board
        
      Additional resources used:
        modeled off of github.com/millerlp/OWHL
        Adapted to use SdFat to save energy required in SD to open and close file to write
*/





#include <Wire.h> //stock Arduino library, used by RTClib
#include <SPI.h> //stock Arduino library, used by SD
#include <RTClib.h> // github.com/adafruit/RTClib
#include <SdFat.h> //github.com/greiman/SdFat

// RTC & SD OBJECTS
RTC_DS3231 rtc; //create real time clock object
SdFat sd; //create sd object
SdFile logfile; //for logging on sd card, this is the file object we will write to
const uint8_t chipSelect = 10; //SD chip select pin, SS


// File name and communication
// Declare initial name for output files written to SD card
// The newer versions of SdFat library support long filenames
char fileName[] = "YYYYMMDD_HHMM_00.CSV";


#define ECHO 1 //set to 1 for debugging printing to Serial, set to 0 to suppress
#define ERROR_LED1 3 // set error LED 
#define ERROR_LED2 4 // set 2nd LED pin 

// Sampling regime
const uint32_t SAMPLE_INTERVAL_MS = 10; // units of milliseconds


#define WRITE_BUFFER 2 //number of readings before and after writes to ignore--a dirty fix to ...
  // deal with spurious measurements at the beginning and end of sensor read cycles, MAY NOT BE NECCESSARY
#define SAMPLE_LEN (1000 + 2*WRITE_BUFFER) //sets number of readings to make in a single burst
#define FILE_CYCLES_TOT 30 //number of sampling bursts to save in one file

// Cases
#define NEWFILE 1
#define READ 2
#define RECORD 3

// Analog pins
#define JOY_X_sig 0         //analog pin for the signal of the x axis from the joystick
#define JOY_Y_sig 1         //               "                 y axis      "
#define BEAM_Z_sig 2        //               "                 z axis from the beam force transducer
#define JOY_X_ref 3         //analog pin for the reference voltage for the instrumentation amp of the x axis from the joystick
#define JOY_Y_ref 4         //               "                                                        y axis       "
#define BEAM_Z_ref 5        //               "                                                        z axis from the beam force transducer

// Book keeping variables
int oldT; // units of milliseconds
int newT; // units of milliseconds
int state;
int nextState;
DateTime startT; // timestamp
int ind;
int cycle;

// Data Arrays
int Time_Values[SAMPLE_LEN];
int F_Values[SAMPLE_LEN][3];
int ref_Values[SAMPLE_LEN][3];

// Error messages stored in flash
#define error(msg) sd.errorHalt(F(msg));



// ----------------------------------------------------------------------------------
// SETUP LOOP
// ----------------------------------------------------------------------------------

void setup() {
  Serial.begin(57600);
  delay (1000);
  
  if(ECHO){
    Serial.println("Beginning startup:");
    Serial.print("  ms delay between samples = ");
    Serial.println(SAMPLE_INTERVAL_MS);
    Serial.println("");
  }
  
  analogReadResolution(12); //read-in analog inputs as 12 bit
  
  pinMode(ERROR_LED1, INPUT); // Set as input first so we can toggle it later
  pinMode(ERROR_LED1, OUTPUT);
  digitalWrite(ERROR_LED1, LOW);
  pinMode(ERROR_LED2, INPUT);
  pinMode(ERROR_LED2, OUTPUT);
  digitalWrite(ERROR_LED2, LOW);
  
  // Briefly flash both LEDs to let user know we're alive
  for (byte i = 0; i < 3; i++){
    digitalWrite(ERROR_LED1, HIGH);
    digitalWrite(ERROR_LED2, HIGH);
    delay(200);
    digitalWrite(ERROR_LED1, LOW);
    digitalWrite(ERROR_LED2, LOW);
    delay(200);
  }
  
  // ---------- RTC SETUP ----------
  Wire1.begin(); // Shield I2C pins connect to alt I2C bus on Arduino Due
  rtc.begin(); // start real time clock
  

  startT = rtc.now();
  if(startT.year() == 2000) {
	// If the clock isn't set, notify the user 
	// by flashing both LEDs on and off 10 times
	// before proceeding. This will still allow 
	// data collection even if the user can't be
	// arsed to set the clock. 
	for (byte i = 0; i < 10; i++) {
		digitalWrite(ERROR_LED1, HIGH);
		delay(500);
		digitalWrite(ERROR_LED2, HIGH);
		digitalWrite(ERROR_LED1, LOW);
		delay(500);
		digitalWrite(ERROR_LED2, LOW);
	}

	
  }
  if(ECHO){
	printTimeSerial(startT);
	Serial.println();
  }
  // ---------- SD SETUP ----------
  if(!sd.begin(chipSelect, SPI_FULL_SPEED)){
	if (ECHO) {
		Serial.println(F("Can't find SD card"));
	}
    // sd.initErrorHalt();
	while (1) {
		// Just idle here flashing the error LED until the
		// user fixes things and restarts the program. 
		digitalWrite(ERROR_LED1, !digitalRead(ERROR_LED1));
		delay(50);

	}
  }
  
  // Starting state
  oldT = millis();
  state = NEWFILE;
}



// ----------------------------------------------------------------------------------
// MAIN LOOP
// ----------------------------------------------------------------------------------

void loop() {
  
    switch(state) {
      
      case NEWFILE:
        if(ECHO){
          Serial.println("state NEWFILE");
        }
        
		startT = rtc.now(); // get a current time stamp
		initFileName(startT); // call initFileName function        
        if(ECHO){
          Serial.println(fileName);
        }
        
        nextState = READ;
        ind = 0;
        cycle = 0;
      break; // NEWFILE
      
      
      case READ:
//        if(ECHO){
//          Serial.println("state READ");
//        }
      
        newT = millis();
		// Compare the newT and oldT values (both in milliseconds)
		// If they are at least SAMPLE_INTERVAL_MS different, make
		// a new sensor reading
        if (newT - oldT >= SAMPLE_INTERVAL_MS) {
          readSensors(ind); // call the readSensor function
          
          ind++; // increment ind after taking a set of readings
          if (ind == SAMPLE_LEN) {
            nextState = RECORD;
          } else {
            nextState = READ;
          }
          oldT = newT;
        }
      break; //READ
      
      case RECORD:
        if(ECHO){
          Serial.println("state RECORD");
        }

        recordMeasures(); // call function to write data to SD card
        clearMeasures(); // reset the data buffers so that no old readings remain
        
        if (cycle < FILE_CYCLES_TOT - 1) {
          cycle++;
          ind = 0;
          nextState = READ;
        } else if (cycle == FILE_CYCLES_TOT - 1) {
          logfile.close();
		  digitalWrite(ERROR_LED2, HIGH);
		  delay(5);
		  digitalWrite(ERROR_LED2, LOW);
          nextState = NEWFILE;
        } else {
          error("Unexpected cycle count value.");
        }
      
      break; //RECORD
    }
    state = nextState;
}
   
    
// ----------------------------------------------------------------------------------
// FUNCTIONS
// ----------------------------------------------------------------------------------

//------------ clearMeasures --------------------------------------------------------

// clears values array, setting all values to -99

void clearMeasures() {
      
  //wipe arrays
  for (int i = 0; i < SAMPLE_LEN; i++) {
    Time_Values[i] = -99;
    F_Values[i][0] = -99;
    F_Values[i][1] = -99;
    F_Values[i][2] = -99;
    ref_Values[i][0] = -99;
    ref_Values[i][1] = -99;
    ref_Values[i][2] = -99;
  }
}

//------------ readSensors ----------------------------------------------------------

// reads sensors values to index in values arrays

void readSensors(int index) {

    //record time of sensor measurement & recording
    Time_Values[index] = millis();
    
    //read x and y axes of sensor 1 and record data in SENS1_Values
    F_Values[index][0] = analogRead(JOY_X_sig);
    F_Values[index][1] = analogRead(JOY_Y_sig);
    F_Values[index][2] = analogRead(BEAM_Z_sig);
    
    //read x and y axes of sensor 1 and record data in SENS1_Values
    ref_Values[index][0] = analogRead(JOY_X_ref);
    ref_Values[index][1] = analogRead(JOY_Y_ref);
    ref_Values[index][2] = analogRead(BEAM_Z_ref);
    
    
    //if using Serial to set zeros, set the zero while there is no force being exerted onto the meters
    if(ECHO && index%10 == 0){
      Serial.print("  ");
      Serial.print(index);
      Serial.print(".\t");
      Serial.print(Time_Values[index]);
      Serial.print("msec\tJOY X: ");
      Serial.print(F_Values[index][0]);
      Serial.print("\tJOY Y: ");
      Serial.print(F_Values[index][1]);
      Serial.print("\tBEAM Z: ");
      Serial.print(F_Values[index][2]);
	  Serial.print("\tRefs:\t");
	  Serial.print(ref_Values[index][0]);
	  Serial.print("\t");
	  Serial.print(ref_Values[index][1]);
	  Serial.print("\t");
	  Serial.println(ref_Values[index][2]);
    }  
}

//------------ recordMeasures -------------------------------------------------------

// Write sensor readings to SD card
// SD line format: Time (millis since program started), JOY_X_sig (analog read, 3.3V = 2095), JOY_Y_sig (analog read), ...
//                 BEAM_Z_sig (analog read), JOY_X_ref (analog read), JOY_Y_ref (analog read), BEAM_Z_ref (analog read)

void recordMeasures() {
  if(ECHO){
    Serial.print("Recording data...");
  }
  
  	// Reopen logfile in case it is closed for some reason
	if (!logfile.isOpen()) {
		if (!logfile.open(fileName, O_RDWR | O_CREAT | O_AT_END)) {
			digitalWrite(ERROR_LED1, HIGH); // turn on error LED
		}
	}
  
  digitalWrite(ERROR_LED2, HIGH);
  for (int i = WRITE_BUFFER; i < SAMPLE_LEN - WRITE_BUFFER; i++) {
    logfile.print( Time_Values[i] );
    logfile.print(F(", "));
    logfile.print( F_Values[i][0] );
    logfile.print(F(", "));
    logfile.print( F_Values[i][1] );
    logfile.print(F(", "));
    logfile.print( F_Values[i][2] );
    logfile.print(F(", "));
    logfile.print( ref_Values[i][0] );
    logfile.print(F(", "));
    logfile.print( ref_Values[i][1] );
    logfile.print(F(", "));
    logfile.println( ref_Values[i][2] );
  }
  
  // logfile.sync();
  digitalWrite(ERROR_LED2, LOW);
  if (ECHO){
    Serial.println(" recording complete.");
    Serial.println("");
  }
  
}

//------------ initFileName --------------------------------------------------------
// A function to generate a new fileName based on the current date and time
// This function will make sure there isn't already a file of the same name
// in existence, then create a new file and call the writeHeader function to 
// insert the standard header into the csv file. 
void initFileName(DateTime time1){
		char buf[5];
		// integer to ascii function itoa(), supplied with numeric year value,
		// a buffer to hold output, and the base for the conversion (base 10 here)
		itoa(time1.year(), buf, 10);
			// copy the ascii year into the filename array
		for (byte i = 0; i <= 4; i++){
			fileName[i] = buf[i];
		}
		// Insert the month value
		if (time1.month() < 10) {
			fileName[4] = '0';
			fileName[5] = time1.month() + '0';
		} else if (time1.month() >= 10) {
			fileName[4] = (time1.month() / 10) + '0';
			fileName[5] = (time1.month() % 10) + '0';
		}
		// Insert the day value
		if (time1.day() < 10) {
			fileName[6] = '0';
			fileName[7] = time1.day() + '0';
		} else if (time1.day() >= 10) {
			fileName[6] = (time1.day() / 10) + '0';
			fileName[7] = (time1.day() % 10) + '0';
		}
		// Insert an underscore between date and time
		fileName[8] = '_';
		// Insert the hour
		if (time1.hour() < 10) {
			fileName[9] = '0';
			fileName[10] = time1.hour() + '0';
		} else if (time1.hour() >= 10) {
			fileName[9] = (time1.hour() / 10) + '0';
			fileName[10] = (time1.hour() % 10) + '0';
		}
		// Insert minutes
			if (time1.minute() < 10) {
			fileName[11] = '0';
			fileName[12] = time1.minute() + '0';
		} else if (time1.minute() >= 10) {
			fileName[11] = (time1.minute() / 10) + '0';
			fileName[12] = (time1.minute() % 10) + '0';
		}
		// Insert another underscore after time
		fileName[13] = '_';
		
		// Next change the counter on the end of the filename
		// (digits 14+15) to increment count for files generated on
		// the same day. This shouldn't come into play
		// during a normal data run, but can be useful when 
		// troubleshooting.
		for (uint8_t i = 0; i < 100; i++) {
			fileName[14] = i / 10 + '0';
			fileName[15] = i % 10 + '0';
			fileName[16] = '.';
			fileName[17] = 'c';
			fileName[18] = 's';
			fileName[19] = 'v';
			
			
			
			if (!sd.exists(fileName)) {
				// when sd.exists() returns false, this block
				// of code will be executed to open the file
				if (!logfile.open(fileName, O_RDWR | O_CREAT | O_AT_END)) {
					// If there is an error opening the file, notify the user
					if (ECHO) {
						Serial.print("Couldn't open file ");
						Serial.println(fileName);
					}
					while (1) {
						// Just idle here flashing the error LED until the
						// user fixes things and restarts the program. 
						digitalWrite(ERROR_LED1, HIGH);
						delay(100);
						digitalWrite(ERROR_LED1, LOW);
						delay(100);
					}
				}
				break; // Break out of the for loop when the
				// statement if(!logfile.exists())
				// is finally false (i.e. you found a new file name to use).
			} // end of if(!sd.exists())
		} // end of file-naming for loop

        logfile.timestamp(T_CREATE, time1.year(), time1.month(), time1.day(), 
                                    time1.hour(), time1.minute(), time1.second());
        logfile.timestamp(T_WRITE, time1.year(), time1.month(), time1.day(), 
                                    time1.hour(), time1.minute(), time1.second());
        logfile.timestamp(T_ACCESS, time1.year(), time1.month(), time1.day(), 
                                    time1.hour(), time1.minute(), time1.second());
        //write header
        writeHeader();
}


//------------ writeHeader ---------------------------------------------------------

// Write data header

void writeHeader() {
	// Reopen logfile in case it is closed for some reason
	if (!logfile.isOpen()) {
		if (!logfile.open(fileName, O_RDWR | O_CREAT | O_AT_END)) {
			digitalWrite(ERROR_LED1, HIGH); // turn on error LED
			if (ECHO) {
				Serial.println("File not found");
			}
		}
	}


  logfile.println(fileName);
  logfile.println(F("Software version LimpetForcemeter.ino"));
  logfile.print(F("Start time "));
  logfile.print(startT.year());
  logfile.print(F("-"));
  logfile.print(startT.month());
  logfile.print(F("-"));
  logfile.print(startT.day());
  logfile.print(F(" "));
  logfile.print(startT.hour());
  logfile.print(F(":"));
  logfile.print(startT.minute());
  logfile.print(F(":"));
  logfile.println(startT.second());
  logfile.print(F("Sample rate set at "));
  logfile.print(1000/SAMPLE_INTERVAL_MS);
  logfile.println(" Hz");
  logfile.println(F("Time(msec), JOY_X_signal, JOY_Y_signal, BEAM_Z_signal, JOY_X_ref, JOY_Y_ref, BEAM_Z_ref"));
  logfile.close();
}


void printTimeSerial(DateTime now){
//------------------------------------------------
// printTime function takes a DateTime object from
// the real time clock and prints the date and time 
// to the serial monitor. 
	Serial.print(now.year(), DEC);
    Serial.print('-');
    Serial.print(now.month(), DEC);
    Serial.print('-');
    Serial.print(now.day(), DEC);
    Serial.print(' ');
    Serial.print(now.hour(), DEC);
    Serial.print(':');
	if (now.minute() < 10) {
		Serial.print("0");
	}
    Serial.print(now.minute(), DEC);
    Serial.print(':');
	if (now.second() < 10) {
		Serial.print("0");
	}
    Serial.print(now.second(), DEC);
	// You may want to print a newline character
	// after calling this function i.e. Serial.println();

}
