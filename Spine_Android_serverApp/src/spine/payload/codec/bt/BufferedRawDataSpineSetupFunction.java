/*****************************************************************
SPINE - Signal Processing In-Node Environment is a framework that 
allows dynamic configuration of feature extraction capabilities 
of WSN nodes via an OtA protocol

Copyright (C) 2007 Telecom Italia S.p.A. 
�
GNU Lesser General Public License
�
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation, 
version 2.1 of the License. 
�
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.� See the GNU
Lesser General Public License for more details.
�
You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA� 02111-1307, USA.
*****************************************************************/

/**
* Implementation of SpineSetupFunction responsible of handling setup of the function type 'Buffered Raw-Data'
* 
* Note that this class is used only internally at the framework.
*
* @author Raffaele Gravina
*
* @version 1.3
*/

package spine.payload.codec.bt;

import spine.SPINEFunctionConstants;
import spine.datamodel.Node;
import spine.datamodel.functions.*;
import spine.exceptions.*;




public class BufferedRawDataSpineSetupFunction extends SpineCodec {

	
	private final static int PARAM_LENGTH = 3; 

	public SpineObject decode(Node node, byte[] payload)throws MethodNotSupportedException {
		throw new MethodNotSupportedException("decode");
	};
    

	public byte[] encode(SpineObject payload) {
		
		spine.datamodel.functions.BufferedRawDataSpineSetupFunction workPayLoad = (spine.datamodel.functions.BufferedRawDataSpineSetupFunction)payload;
		
		byte[] data = new byte[2 + PARAM_LENGTH];
	
		data[0] = SPINEFunctionConstants.BUFFERED_RAW_DATA;
		data[1] = PARAM_LENGTH;

		data[2] = workPayLoad.getSensor();
		data[3] = (byte)workPayLoad.getBufferSize();
		data[4] = (byte)workPayLoad.getShiftSize();
		
		return data;	
	}
}
