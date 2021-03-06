/*****************************************************************
 SPINE - Signal Processing In-Note Environment is a framework that 
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
 * Module component of the SPINE Buffered Raw-Data Engine.
 *
 *
 * @author Raffaele Gravina
 *
 * @version 1.3
 */

#ifndef SENSORS_REGISTRY_SIZE
#define SENSORS_REGISTRY_SIZE 16   // we can have up to 16 sensors because they are addressed with 4bits into the SPINE comm. protocol
#endif

module BufferedRawDataEngineP {

	provides interface Function;

	uses {
		interface Boot;
		interface FunctionManager;
		interface SensorsRegistry;
		interface SensorBoardController;
		interface BufferPool;
	}
}

implementation {
	
	buffered_rawdata_params_t paramsList[SENSORS_REGISTRY_SIZE];  // <sensorCode, chsBitmask, bufferSize, shiftSize, samplesCount>
	uint8_t paramsIndex = 0;

        uint8_t activeSensorsList[SENSORS_REGISTRY_SIZE];
        uint8_t activeSensorsIndex = 0;

	uint16_t msg[128];
	uint8_t msgByte[256];

	bool registered = FALSE;
        bool computingStarted = FALSE;

        event void Boot.booted() {
		if (!registered) {
			call FunctionManager.registerFunction(BUFFERED_RAWDATA);
			registered = TRUE;
		}
	}
	
	
	command bool Function.setUpFunction(uint8_t* functionParams, uint8_t functionParamsSize) {
		uint8_t i;

		uint8_t sensCode;
		uint8_t bufferSize;
		uint8_t shiftSize;

		if (functionParamsSize != 3)
		   return FALSE;

                sensCode = functionParams[0];
		bufferSize = functionParams[1];
		shiftSize = functionParams[2];

                for (i = 0; i<paramsIndex && i<SENSORS_REGISTRY_SIZE; i++)
                   if (paramsList[i].sensorCode == sensCode) {
                      paramsList[i].bufferSize = bufferSize;
                      paramsList[i].shiftSize = shiftSize;
                      paramsList[i].samplesCount = 0;
                      break;
                   }

                if (i == paramsIndex) {
                   paramsList[paramsIndex].sensorCode = sensCode;
                   paramsList[paramsIndex].bufferSize = bufferSize;
                   paramsList[paramsIndex].shiftSize = shiftSize;
                   paramsList[paramsIndex++].samplesCount = 0;
                }

                return TRUE;
	}

	command bool Function.activateFunction(uint8_t* functionParams, uint8_t functionParamsSize) {
                bool activated = FALSE;
                uint8_t i;

                if (functionParamsSize != 2)
		   return FALSE;

                for (i = 0; i<paramsIndex && i<SENSORS_REGISTRY_SIZE; i++) {
                   if (paramsList[i].sensorCode == functionParams[0])
                      paramsList[i].chsBitmask = functionParams[1];
                   if (activeSensorsList[i] == functionParams[0])
                      activated = TRUE;
                }

                if (!activated)
                   activeSensorsList[activeSensorsIndex++] = functionParams[0];


                return TRUE;
	}

	command bool Function.disableFunction(uint8_t* functionParams, uint8_t functionParamsSize) {
		uint8_t j, k;

		uint8_t sensorCode;

		if (functionParamsSize != 2)
		   return FALSE;

		sensorCode = functionParams[0];

		for(j = 0; j<activeSensorsIndex; j++) {
		   if (activeSensorsList[j] == sensorCode) {
  		      for ( k = j; k<activeSensorsIndex-1; k++)
		         activeSensorsList[k] = activeSensorsList[k+1];
		      activeSensorsList[--activeSensorsIndex] = 0;
		      break;
		   }
		}

		//if (activeSensorsIndex == 0xFF)  // CHECK
		  // computingStarted = FALSE;

		return TRUE;
	}
	
	command uint8_t* Function.getSubFunctionList(uint8_t* functionCount) {
		*functionCount = 0;
		return NULL;
	}
	
	command void Function.startComputing() {				
		computingStarted = TRUE;
	}

	command void Function.stopComputing() {
		computingStarted = FALSE;
	}
	
	event void BufferPool.newElem(uint8_t bufferID, uint16_t elem) {}
	
	bool isActive(uint8_t sensCode) {
           uint8_t i;
           
           for (i = 0; i<activeSensorsIndex; i++)
              if (activeSensorsList[i] == sensCode)
                 return TRUE;

           return FALSE;
        }

	event void FunctionManager.sensorWasSampledAndBuffered(enum SensorCode sensorCode) {
                
             uint16_t tmp;
             uint8_t retMask = 0;
             uint8_t mask = 0x08;
             uint8_t i, j;
             uint8_t chsCount = 0;
             
             if (computingStarted) {
                for (i = 0; i<paramsIndex; i++) {
                   if (paramsList[i].sensorCode == sensorCode && isActive(sensorCode)) {
                      paramsList[i].samplesCount++;
                      if (paramsList[i].samplesCount == paramsList[i].shiftSize) {
                         //tmp = (sensorCode<<4 | paramsList[i].chsBitmask);
                         //msg[0] = sizeof(uint16_t)<<8 | tmp;
                         msg[1] = paramsList[i].bufferSize<<8;
                         
                         for (j = 0; j<MAX_VALUE_TYPES; j++) {
                            if ( ((paramsList[i].chsBitmask & (mask>>j)) == (mask>>j)) && call SensorBoardController.canSense(sensorCode, j)) {
                               call BufferPool.getData(call SensorsRegistry.getBufferID(sensorCode, j), paramsList[i].bufferSize, msg+(2+paramsList[i].bufferSize*chsCount));
                               retMask |= (mask>>j);
                               chsCount++;
                            }
                         }
                         
                         tmp = (sensorCode<<4 | retMask);
                         msg[0] = sizeof(uint16_t)<<8 | tmp;

                         paramsList[i].samplesCount = 0;
                         
                         memcpy(msgByte, msg, (2+paramsList[i].bufferSize*chsCount)*sizeof(uint16_t) );
                         call FunctionManager.send(BUFFERED_RAWDATA, msgByte, (2+paramsList[i].bufferSize*chsCount)*sizeof(uint16_t));
                      }
                      break;
                   }
                }
             }
	}
	
	event void SensorBoardController.acquisitionStored(enum SensorCode sensorCode, error_t result, int8_t resultCode){}
}

