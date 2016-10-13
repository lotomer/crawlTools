package org.tomstools.nutch.parse.html;

public interface ValueTransferable {
	/**
	 * 将输入转换后输出
	 * @param input 待转换数据
	 * @return 转换后结果
	 */
	public String transfer(String input);
}
