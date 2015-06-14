/* Limpet_force_meter.ino

      Last edit: 2015 06 13 LPM
      
      Software to run one joystick force transducer and associated cantilever forve transducer on 
      battery power to measure forces of oystercatcher predatory strike on a model limpet. 
      
      Burst samples at a rate set by SAMPLE_INTERVAL_MS for SAMPLE_LEN milliseconds then pauses to
      write to card. Opens a file then repeats burst sampling, going through FILE_CYCLES_TOT number 
      of cycles before closing current file and then opening a new one. Output file name is set by 
      FILE_BASE_NAME with a 3 digit count that automatically increments to the next available file name.
      
      Designed to burst sample at 100Hz and make single files of a 5 min length each.
      
      
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
RTC_DS1307 rtc; //create real time clock object
SdFat sd; //create sd object
SdFile logfile; //for logging on sd card, this is the file object we will write to
const uint8_t chipSelect = 10; //SD chip select pin, SS
//SPI write speed, if write is too fast use SPI_HALF_SPEED or SPI_QUARTER_SPEED:
const uint8_t spiSpeed = SPI_FULL_SPEED;

// File name and communication
#define FILE_BASE_NAME "TR1_" //max 4 charcters
const uint8_t BASE_NAME_SIZE = sizeof(FILE_BASE_NAME) - 1;
char fileName[13] = FILE_BASE_NAME"000.csv";

#define ECHO 0 //set to 1 for debugging printing to Serial, set to 0 to suppress
#define ERROR_LED1 6 //set error LED pin for RTC reset error
#define ERROR_LED2 7

// Sampling regime
const uint32_t SAMPLE_INTERVAL_MS = 10;
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
int oldT;
int newT;
int state;
int nextState;
DateTime startT;
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
  Serial.begin(9600);
  delay (1000);
  
  if(ECHO){
    Serial.println("Beginning startup:");
    Serial.print("  ms delay between samples = ");
    Serial.println(SAMPLE_INTERVAL_MS);
    Serial.println("");
  }
  
  analogReadResolution(12); //read-in analog inputs as 12 bit
  pinMode(ERROR_LED1, OUTPUT);
  digitalWrite(ERROR_LED1, LOW);
  
  // ---------- RTC SETUP ----------
  Wire1.begin(); // Shield I2C pins connect to alt I2C bus on Arduino Due
  rtc.begin(); // start real time clock
  

  startT = rtc.now();
  if(startT.year() == 2000) {
    digitalWrite(ERROR_LED1, HIGH);
    delay(500);
    digitalWrite(ERROR_LED1, LOW);
    delay(500);
    digitalWrite(ERROR_LED1, HIGH);
  }
  
  // ---------- SD SETUP ----------
  if(!sd.begin(chipSelect, SPI_FULL_SPEED)){
    sd.initErrorHalt();
  }
  if(BASE_NAME_SIZE > 6){
    error("FILE_BASE_NAME is too long");
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
        
        // ---------- GENERATE FILENAME & CREATE FILE ----------
        //find next available file name
        while(sd.exists(fileName)){
          //ones digit
          if(fileName[BASE_NAME_SIZE + 2] != '9'){
            fileName[BASE_NAME_SIZE + 2]++;
          }
          //tens digit
          else if(fileName[BASE_NAME_SIZE + 1] != '9'){
            fileName[BASE_NAME_SIZE + 2] = '0';
            fileName[BASE_NAME_SIZE + 1]++;
          }
          //hundreds digit
          else if(fileName[BASE_NAME_SIZE] != '9'){
            fileName[BASE_NAME_SIZE + 2] = '0';
            fileName[BASE_NAME_SIZE + 1] = '0';
            fileName[BASE_NAME_SIZE + 0]++;
          } else {
            error("Can't create file name.");
          }
        }
        //open new file
        if(!logfile.open(fileName, O_CREAT | O_WRITE | O_EXCL)) {
          error("file.open");
        }
        logfile.timestamp(T_CREATE, startT.year(), startT.month(), startT.day(), 
                                    startT.hour(), startT.minute(), startT.second());
        logfile.timestamp(T_WRITE, startT.year(), startT.month(), startT.day(), 
                                    startT.hour(), startT.minute(), startT.second());
        logfile.timestamp(T_ACCESS, startT.year(), startT.month(), startT.day(), 
                                    startT.hour(), startT.minute(), startT.second());
        //write header
        writeHeader();
        //logfile.close();
        
        
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
        if (newT - oldT > SAMPLE_INTERVAL_MS) {
          readSensors(ind);
          
          ind++;
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

        recordMeasures();
        clearMeasures();
        
        if (cycle < FILE_CYCLES_TOT - 1) {
          cycle++;
          ind = 0;
          nextState = READ;
        } else if (cycle == FILE_CYCLES_TOT - 1) {
          logfile.close();
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
    F_Values[i][1] = -99;
    F_Values[i][2] = -99;
    F_Values[i][3] = -99;
    ref_Values[i][1] = -99;
    ref_Values[i][2] = -99;
    ref_Values[i][3] = -99;
  }
}

//------------ readSensors ----------------------------------------------------------

// reads sensors values to index in values arrays

void readSensors(int index) {

    //record time of sensor measurement & recording
    Time_Values[index] = millis();
    
    //read x and y axes of sensor 1 and record data in SENS1_Values
    F_Values[index][1] = analogRead(JOY_X_sig);
    F_Values[index][2] = analogRead(JOY_Y_sig);
    F_Values[index][3] = analogRead(BEAM_Z_sig);
    
    //read x and y axes of sensor 1 and record data in SENS1_Values
    ref_Values[index][1] = analogRead(JOY_X_ref);
    ref_Values[index][2] = analogRead(JOY_Y_ref);
    ref_Values[index][3] = analogRead(BEAM_Z_ref);
    
    
    //if using Serial to set zeros, set the zero while there is no force being exerted onto the meters
    if(ECHO && index%10 == 0){
      Serial.print("  ");
      Serial.print(index);
      Serial.print(". ");
      Serial.print(Time_Values[index]);
      Serial.print(" msec // JOY X: ");
      Serial.print(F_Values[index][1]);
      Serial.print(", JOY Y: ");
      Serial.print(F_Values[index][2]);
      Serial.print(" // BEAM Z: ");
      Serial.print(F_Values[index][3]);
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
  
  for (int i = WRITE_BUFFER; i < SAMPLE_LEN - WRITE_BUFFER; i++) {
    logfile.print( Time_Values[i] );
    logfile.print( ", " );
    logfile.print( F_Values[i][1] );
    logfile.print( ", " );
    logfile.print( F_Values[i][2] );
    logfile.print( ", " );
    logfile.print( F_Values[i][3] );
    logfile.print( ", " );
    logfile.print( ref_Values[i][1] );
    logfile.print( ", " );
    logfile.print( ref_Values[i][2] );
    logfile.print( ", " );
    logfile.print( ref_Values[i][3] );
  }
  
  if (ECHO){
    Serial.println(" recording complete.");
    Serial.println("");
  }
  
}

//------------ writeHeader ---------------------------------------------------------

// Write data header

void writeHeader() {
  logfile.println(fileName);
  logfile.println();
  logfile.println("Software version LimpetForcemeter.ino");
  logfile.print("Start time ");
  logfile.print(startT.year());
  logfile.print("/");
  logfile.print(startT.month());
  logfile.print("/");
  logfile.print(startT.day());
  logfile.print(" ");
  logfile.print(startT.hour());
  logfile.print(":");
  logfile.print(startT.minute());
  logfile.print(":");
  logfile.println(startT.second());
  logfile.print("Sample rate set at ");
  logfile.print(1000/SAMPLE_INTERVAL_MS);
  logfile.println(" Hz");
  logfile.println("");
  logfile.println("Time(msec), JOY_X_sig, JOY_Y_sig, BEAM_Z_sig, JOY_X_ref, JOY_Y_ref, JOY_Z_ref");
}


