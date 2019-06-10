# -*- coding: utf-8 -*-
"""
Created:    Wed Jun  5 14:51:49 2019
Author:     liuyao8
Descritipn: 
"""

import cv2
import numpy as np
from sklearn.preprocessing import minmax_scale

# Histogram Array
h1 = np.array([1, 2, 3, 4, 5, 6], dtype=np.float32)   # 需要指定为float32类型，否则报错
h2 = np.array([2, 3, 0, 5, 6, 7], dtype=np.float32)

# MinMax归一化 参考Article
h1_n = minmax_scale(h1)
h2_n = minmax_scale(h2)

# 遍历各种Metricss
methods = [(cv2.HISTCMP_CORREL, 0, '相关系数'), (cv2.HISTCMP_CHISQR, 1, '卡方'), 
           (cv2.HISTCMP_INTERSECT, 2, '十字'), (cv2.HISTCMP_BHATTACHARYYA, 3, '巴氏系数'), 
           (cv2.HISTCMP_HELLINGER, 3, '同巴氏系数'), (cv2.HISTCMP_CHISQR_ALT, 4, '调整的卡方'), 
           (cv2.HISTCMP_KL_DIV, 5, 'KL散度or相对熵')]
for method, method_id, method_name in methods:
    print('Method-' + str(method) + ': ' + str(round(cv2.compareHist(h1_n, h2_n, method), 4)), method_name)


