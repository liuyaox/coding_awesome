# -*- coding: utf-8 -*-
"""
Created:    2019-07-15
Author:     liuyao8
Descritipn: 
"""

import jieba
from gensim import corpora, models


# 1. 语料建立
# 原始语料： iterable of document (str)
raw_documents = [  
    '0无偿居间介绍买卖毒品的行为应如何定性',  
    '1吸毒男动态持有大量毒品的行为该如何认定',  
    '2如何区分是非法种植毒品原植物罪还是非法制造毒品罪',  
    '3为毒贩贩卖毒品提供帮助构成贩卖毒品罪',  
    '4将自己吸食的毒品原价转让给朋友吸食的行为该如何认定',  
    '5为获报酬帮人购买毒品的行为该如何认定',  
    '6毒贩出狱后再次够买毒品途中被抓的行为认定',  
    '7虚夸毒品功效劝人吸食毒品的行为该如何认定',  
    '8妻子下落不明丈夫又与他人登记结婚是否为无效婚姻',  
    '9一方未签字办理的结婚登记是否有效',  
    '10夫妻双方1990年按农村习俗举办婚礼没有结婚证 一方可否起诉离婚',  
    '11结婚前对方父母出资购买的住房写我们二人的名字有效吗',  
    '12身份证被别人冒用无法登记结婚怎么办？',  
    '13同居后又与他人登记结婚是否构成重婚罪',  
    '14未办登记只举办结婚仪式可起诉离婚吗',
    '15同居多年未办理结婚登记，是否可以向法院起诉要求离婚'  
]

# 初级语料：iterable of document(iterable of str)
texts = [[word for word in jieba.cut(document, cut_all=True)] for document in raw_documents]


# 基于初级语料，建立字典和正式语料 corpus
dictionary = corpora.Dictionary(texts)                  # 先建立字典
dictionary.filter_extremes(no_below=5, no_above=0.8)    # 按词频过滤单词

corpus = [dictionary.doc2bow(text) for text in texts]   # 再建立正式语料
corpora.MmCorpus.serialize('xxx.mm', corpus)            # 持久化到本地
corpus = corpora.MmCorpus('xxx.mm')                     # 从本地加载


# 2. 模型训练和应用
# corpus 可用于 TFIDF, LSI, LDA 等模型
# TFIDF
tfidf = models.TfidfModel(corpus)   # 基于正式语料训练模型
matrix = tfidf[corpus]              # 应用模型
for vector in matrix:
    print(vector)

