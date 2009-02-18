/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jabezhelper;

import com.illposed.osc.*;
import java.util.Date;
import java.util.Enumeration;
import java.util.Hashtable;


/**
 * @author tomn
 * rework OSCPacketDispatcher from javaosc to response to all osc messages
 *
 */

/**
 * @author cramakrishnan
 *
 * Copyright (C) 2003, C. Ramakrishnan / Auracle
 * All rights reserved.
 *
 * See license.txt (or license.rtf) for license information.
 *
 * Dispatches OSCMessages to registered listeners.
 *
 */

public class OSCPacketDispatcher {
	// use Hashtable for JDK1.1 compatability
    private OSCListener listener;

	/**
	 *
	 */
	public OSCPacketDispatcher() {
		super();
	}

	public void addListener(OSCListener listener) {
		this.listener = listener;
	}

	public void dispatchPacket(OSCPacket packet) {
		if (packet instanceof OSCBundle)
			dispatchBundle((OSCBundle) packet);
		else
			dispatchMessage((OSCMessage) packet);
	}

	public void dispatchPacket(OSCPacket packet, Date timestamp) {
		if (packet instanceof OSCBundle)
			dispatchBundle((OSCBundle) packet);
		else
			dispatchMessage((OSCMessage) packet, timestamp);
	}

	private void dispatchBundle(OSCBundle bundle) {
		Date timestamp = bundle.getTimestamp();
		OSCPacket[] packets = bundle.getPackets();
		for (int i = 0; i < packets.length; i++) {
			dispatchPacket(packets[i], timestamp);
		}
	}

	private void dispatchMessage(OSCMessage message) {
		dispatchMessage(message, null);
	}

	private void dispatchMessage(OSCMessage message, Date time) {
    	listener.acceptMessage(time, message);
	}
}
