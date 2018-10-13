



/*
Devices needed to connect:

1. LCD display (+PCF8574T (I2C)
2. Temperature/humidity DHT 11/22 (I2C)
3. Soil humidity sensor (Analog)
4. Pump (Analog) 
5. Temperature DS18B20 (1Wire)
6. Joystick (Analog)
7. Keyboard (???) 
*/


/*
###### NOTES:

1. About LCD: before each piece of information I clear the whole display


2. There are a lot of delays in the code, when fully written the code someday might be improved by writing the full code`s scenario and feeling those delays with tasks
   that should be done besides the current operation.

*/

//Include all the libraries 



#include <LiquidCrystal_I2C.h> //LCD
#include <OneWire.h> //DS18B20 - temperature sensor
#include <Wire.h> // General I2C library 
#include <DHT.h> // Air temperature/Humidity sensor - DHT 11 (also for DHT 22 (more wide range of use))



//Set the key parameters before cycles

// 1. LCD
LiquidCrystal_I2C lcd(0x27,16,2);  // set the LCD address to 0x27 for a 16 chars and 2 line display 
                                   // The adress can be obtained by using I2c Scanner sketch for arduino (check out files on ya.disk)

// 2. Air humidity/temperature (DHT 11)

  #define DHTPIN 8 
  //Sensor initialization
  DHT dht(DHTPIN, DHT11);

// 3. Soil humidity sensor (ADC)

  // Here we set persentage values and we`ll be using map() function which purpose is to convert one scale to another

  int dryValue = 1000;
  int wetValue = 400;

  int persentageDryValue = 0;
  int persentageWetValue = 100;                                    

// 5. Temperature DS18B20 (1Wire)
  OneWire  oneWireBus(10);  // on pin 10 (a 4.7K resistor is necessary)

void setup() {
  
  // Basic parameters
  Serial.begin(9600);              // set the baud rate

  // 1. LCD display (+PCF8574T (I2C)
  lcd.init();                    // initialize the lcd 
  lcd.backlight();               // It is supposed to turn it on (???)
  
  
  // Print a message to the LCD.
  lcd.setCursor(1,0);              // raw / column
  lcd.print("Hello, world!"); // main comand for printing on screen


  // 2. Temperature/humidity DHT 11/22 (I2C)
  
  // Probably begin to scan all the DHT sensors
  dht.begin();
  // 3. Soil humidity sensor (Analog)



  // 4. Pump (Analog) 


  // 5. Temperature DS18B20 (1Wire)

  
  // 6. Joystick (Analog)


  // 7. Keyboard (???)     

}



void loop() {


  // 2. Temperature/humidity DHT 11/22 (I2C)

  //read humidity
  float airHumidity = dht.readHumidity();
  //Read temperature
  float airTemperature = dht.readTemperature();
  // Check if reading is successful

    if (isnan(airHumidity) || isnan(airTemperature)) {
      
      Serial.println("Cannot read the values");
      return;
    }
    Serial.print("Air Humidity ");
    Serial.print( airHumidity,2);
    Serial.println ("%");
    
    Serial.print("Air temperature ");
    Serial.println( airTemperature,2);


  // 3. Soil humidity sensor (Analog)
  // read the input on analog pin 0:
  
  int rawValue = analogRead(A0);
  int persentageWetValue = map(rawValue, dryValue, wetValue, persentageDryValue, persentageWetValue);
  Serial.print (persentageWetValue);
  Serial.println ("%");
 /*
  int sensorDigitalValue = digitalRead(9);
  
  Serial.println(sensorValue);
  Serial.println(sensorDigitalValue);
  delay(100);
*/
  // 4. Pump (Analog) 

  // 6. Joystick (Analog)
  // 7. Keyboard (???) 




  // 5. Temperature DS18B20 (1Wire)

  byte i;
  byte oneWireDevicePresent = 0;
  byte type_s;
  byte data[12];
  byte addr[8];
  float celsius, fahrenheit;

  // find sensor's address
  if ( !oneWireBus.search(addr) ) {
    Serial.println("No more addresses.");
    Serial.println();
    oneWireBus.reset_search();
    delay(250);
    return;
  }
  // show it on Serial
  Serial.print("OneWire device address (ROM) =");
  for( i = 0; i < 8; i++) {
    Serial.write(' ');
    Serial.print(addr[i], HEX);
  }
  Serial.println();

  // complain and return if ___
  if (OneWire::crc8(addr, 7) != addr[7]) {
      Serial.println("CRC is not valid!");
      return;
  }
 
  // the first ROM byte indicates which chip
  switch (addr[0]) {
    case 0x10:
      Serial.println("  Chip = DS18S20");  // or old DS1820
      type_s = 1;
      break;
    case 0x28:
      Serial.println("  Chip = DS18B20");
      type_s = 0;
      break;
    case 0x22:
      Serial.println("  Chip = DS1822");
      type_s = 0;
      break;
    default:
      Serial.println("Device is not a DS18x20 family device.");
      return;
  } 

  oneWireBus.reset();
  oneWireBus.select(addr);
  oneWireBus.write(0x44);// with ordinary feeding, with parasite ( all data pins are connected to the feeding through 4,7k resistor in a single point) write          //oneWireBus.write(0x44, 1);
                         // the command goes from DS18B20 datasheet
  delay(1000);           // maybe 750ms is enough, maybe not
                         // we might do a oneWireBus.depower() here, but the reset will take care of it. 
  
  oneWireDevicePresent = oneWireBus.reset();
  oneWireBus.select(addr);
  oneWireBus.write(0xBE);         // Read Scratchpad

  Serial.print("  Data = ");
  Serial.print(oneWireDevicePresent, HEX);
  Serial.print(" ");
  for ( i = 0; i < 9; i++ ) {           // we need 9 bytes
    data[i] = oneWireBus.read();
    Serial.print(data[i], HEX);
    Serial.print(" ");
  }
  Serial.print(" CRC=");
  Serial.print(OneWire::crc8(data, 8), HEX);
  Serial.println();

  // Convert the data to actual temperature
  // because the result is a 16 bit signed integer, it should
  // be stored to an "int16_t" type, which is always 16 bits
  // even when compiled on a 32 bit processor.
  int16_t raw = (data[1] << 8) | data[0];
  if (type_s) {
    raw = raw << 3; // 9 bit resolution default
    if (data[7] == 0x10) {
      // "count remain" gives full 12 bit resolution
      raw = (raw & 0xFFF0) + 12 - data[6];
    }
  } else {
    byte cfg = (data[4] & 0x60);
    // at lower res, the low bits are undefined, so let's zero them
    if (cfg == 0x00) raw = raw & ~7;  // 9 bit resolution, 93.75 ms
    else if (cfg == 0x20) raw = raw & ~3; // 10 bit res, 187.5 ms
    else if (cfg == 0x40) raw = raw & ~1; // 11 bit res, 375 ms
    //// default is 12 bit resolution, 750 ms conversion time
  }
  celsius = (float)raw / 16.0;
  fahrenheit = celsius * 1.8 + 32.0;
  Serial.print("  Temperature = ");
  
  lcd.clear();
  lcd.setCursor(0,0);              // column /raw
  lcd.print("Temperature"); 
  
  
  Serial.print(celsius);
  Serial.print(" Celsius, ");
  
  lcd.setCursor(11,0);              // column /raw 
  lcd.print(celsius);  
  lcd.setCursor(15,0);              // column /raw 
  lcd.print("C");  
  
  Serial.print(fahrenheit);
  Serial.println(" Fahrenheit");


  
}





