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


package logic;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Properties;



/**
*
* This is the Controller that centralize the Read-Write access to the 
* application app.properties file. It is used to store and load permanent parameters
* and other variable configurations.   
*
* @author Raffaele Gravina
* @author Antonio Guerrieri
*
* @version 1.0 - 2008.01.04
*/
public class PropertiesController {
	
	final static String PROPERTIES_FILE_PATH = "resources/app.properties";
	
	private String DEFAULT_COMMENT = "Created by the PropertiesController";
	
	private static PropertiesController propController;
	
	private Properties p;
	
	private boolean loaded = false;
	
	public static PropertiesController getInstance() {
		if (propController == null)
			propController = new PropertiesController();
		return propController;		
	}
	
	private PropertiesController() {
		p = new Properties();				
	}
	
	public void load() {
		if (!loaded)
			try {
				p.load(new FileInputStream(PROPERTIES_FILE_PATH));
				loaded = true;
			} catch (IOException e) {
				e.printStackTrace();
			}
	}
	
	public void store() {
		try {
			p.store(new FileOutputStream(PROPERTIES_FILE_PATH), DEFAULT_COMMENT);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public String getProperty(String key) {
		load();
		return p.getProperty(key);
	}
	
	public void setProperty(String key, String value) {
		p.setProperty(key, value);
	}
	
	public Object remove(String key) {
		return p.remove(key);
	}
	
	
}
