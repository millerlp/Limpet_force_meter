Design files, data, and analysis files from the manuscript "Temperature affects susceptibility of intertidal limpets to bird predation"
Rachel J. Pound, Luke P. Miller, Felicia A. King, Jennifer L. Burnaford
Journal of Experimental Biology 2020 : jeb.213595 doi: 10.1242/jeb.213595

R analysis code and data used in the production of the paper are in the 'R_analysis_files_data/' directory. 

Circuit board designs for the three-dimensional force transducer are in the 'Eagle_files/' directory. These files were
produced with the software Eagle, https://www.autodesk.com/products/eagle/overview. This circuit board is designed to 
attach to an Arduino Due in order to operate. 

Software used to run the 3-dimensional force transducer datalogger are in the 'Arduino_files/' directory. These can
be used with the Arduino software available at https://arduino.cc. The subdirectories in the Arduino_files/ directory should be
installed in the user's "Arduino" directory. 

The Arduino programs here require the following libraries to be installed:
https://github.com/millerlp/RTClib
https://github.com/greiman/SdFat

Limpet_force_meter.ino can be loaded onto the Arduino Due to log data from the force transducer.
Limpet_force_calibration.ino can be loaded to both log data and also to provide a calibration routine that will write data to the SD card as the user hangs weights of various masses off of the 3 axes of the transducer. 

Hardware and software authored by Felicia King and Luke Miller, 2015

