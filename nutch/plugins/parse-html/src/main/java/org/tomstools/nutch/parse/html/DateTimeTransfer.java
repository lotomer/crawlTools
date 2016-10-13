/**
 * 
 */
package org.tomstools.nutch.parse.html;

import java.text.ParseException;
import java.text.SimpleDateFormat;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * @author Administrator
 *
 */
public class DateTimeTransfer implements ValueTransferable {
	private static final Logger LOG = LoggerFactory.getLogger(DateTimeTransfer.class);
	private SimpleDateFormat formatter;
	public DateTimeTransfer(String format){
		this.formatter = new SimpleDateFormat(format);
	}
	public String transfer(String input) {
		try {
			return String.valueOf(formatter.parse(input).getTime() / 1000);
		} catch (ParseException e) {
			LOG.error(e.getMessage(),e);
		}
		return null;
	}

}
