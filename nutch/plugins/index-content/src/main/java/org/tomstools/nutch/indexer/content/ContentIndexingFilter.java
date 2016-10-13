package org.tomstools.nutch.indexer.content;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.io.Text;
import org.apache.nutch.crawl.CrawlDatum;
import org.apache.nutch.crawl.Inlinks;
import org.apache.nutch.indexer.IndexingException;
import org.apache.nutch.indexer.IndexingFilter;
import org.apache.nutch.indexer.NutchDocument;
import org.apache.nutch.parse.Parse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ContentIndexingFilter implements IndexingFilter{
	private static final Logger LOG = LoggerFactory.getLogger(ContentIndexingFilter.class);
	private Configuration conf;
	private int minContentLength;
	public Configuration getConf() {
		return conf;
	}

	public void setConf(Configuration conf) {
		this.conf = conf;
		this.minContentLength = conf.getInt("indexer.min.content.length", 1);
	}

	public NutchDocument filter(NutchDocument doc, Parse parse, Text url,
			CrawlDatum datum, Inlinks inlinks) throws IndexingException {
		if (null == doc){
			return doc;
		}
		// 正文内容少于指定长度则过滤掉
		String content = parse.getText();
		if (content.length() < minContentLength){
			LOG.info("Filtered: " + url);
			return null;
		}else{
			return doc;
		}
	}

}
