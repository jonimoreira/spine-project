/*****************************************************************
SPINE - Signal Processing In-Node Environment is a framework that
allows dynamic configuration of feature extraction capabilities 
of WSN nodes via an OtA protocol

Copyright (C) 2007 Telecom Italia S.p.A. 
 
GNU Lesser General Public License
 
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation, 
version 2.1 of the License. 
 
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.
 
You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.
*****************************************************************/

/**
 * Module component of the 'MTS300 sensorboard' dual-axis Accelerometer sensor driver
 * for the micaz platform
 *
 * @author Raffaele Gravina <rgravina@wsnlabberkeley.com>
 *
 * @version 1.2
 */

module HilAccSensorP {
  uses {
     interface Read<uint16_t> as AccelX;
     interface Read<uint16_t> as AccelY;
     
     interface Boot;
     interface SensorsRegistry;
  }

  provides interface Sensor;
}

implementation {
  
    uint16_t accX = 0;
    uint16_t accY = 0;

    uint8_t acqType;
    bool xReady;
    bool yReady;
    
    uint8_t valueTypesList[2];

    uint8_t acquireTypesList[3];
    
    bool registered = FALSE;


    event void Boot.booted() {
       if (!registered) {
          valueTypesList[0] = CH_1;
          valueTypesList[1] = CH_2;
          acquireTypesList[0] = CH_1_ONLY;
          acquireTypesList[1] = CH_2_ONLY;
          acquireTypesList[2] = ALL;

          // the driver self-registers to the sensor registry
          call SensorsRegistry.registerSensor(ACC_SENSOR);

          registered = TRUE;
       }
    }

    command uint8_t Sensor.getSignificantBits() {
        return 12;
    }

    command error_t Sensor.acquireData(enum AcquireTypes acquireType) {
        xReady = FALSE;
        yReady = FALSE;

        acqType = acquireType;

        if(acquireType == ALL || acquireType == CH_1_ONLY)
            call AccelX.read();
        if(acquireType == ALL || acquireType == CH_2_ONLY)
            call AccelY.read();

        return SUCCESS;
    }

    command uint16_t Sensor.getValue(enum ValueTypes valueType) {
        switch (valueType) {
            case CH_1 : return accX;
            case CH_2 : return accY;
            default : return 0xffff;
        }
    }

    command void Sensor.getAllValues(uint16_t* buffer, uint8_t* valuesNr) {
        *valuesNr = sizeof valueTypesList;
        buffer[0] = accX;
        buffer[1] = accY;
    }

    command enum SensorCode Sensor.getSensorCode() {
        return ACC_SENSOR;
    }

    command uint16_t Sensor.getSensorID() {
        return 0xaa3f; // the ID has been randomly choosen
    }

    /*
    * The event is thrown when a new gyroscope x-axis reading is ready.
    * It sets a global variable and put the reading in the system buffer.
    *
    * @param result : indicates whether the reading process has succeed or not.
    * @param data : if the result is <code>SUCCESS</code>, it contains a consistent reading.
    *
    * @return void
    */
    event void AccelX.readDone(error_t result, uint16_t data) {
        xReady = TRUE;

        accX = data;

        if ((acqType == ALL && yReady) || acqType == CH_1_ONLY)   // the acquisitionDone is not signaled until every channel values are ready
           signal Sensor.acquisitionDone(result, acqType);
    }

    /*
    * The event is thrown when a new gyroscope y-axis reading is ready.
    * It sets a global variable and put the reading in the system buffer.
    *
    * @param result : indicates whether the reading process has succeed or not.
    * @param data : if the result is <code>SUCCESS</code>, it contains a consistent reading.
    *
    * @return void
    */
    event void AccelY.readDone(error_t result, uint16_t data) {
        yReady = TRUE;

        accY = data;

        if ((acqType == ALL && xReady) || acqType == CH_2_ONLY)   // the acquisitionDone is not signaled until every channel values are ready
           signal Sensor.acquisitionDone(result, acqType);
    }

    command uint8_t* Sensor.getValueTypesList(uint8_t* valuesTypeNr) {
        *valuesTypeNr = sizeof valueTypesList;
        return valueTypesList;
    }

    command uint8_t* Sensor.getAcquireTypesList(uint8_t* acquireTypesNr) {
        *acquireTypesNr = sizeof acquireTypesList;
        return acquireTypesList;
    }
}


