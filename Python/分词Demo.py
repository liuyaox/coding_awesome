# -*- coding: utf-8 -*-
"""
Created on Mon Oct 22 17:00:08 2018
@author: liuyao8
"""

import thulac

thu1 = thulac.thulac()
text1 = thu1.cut("我爱北京天安门", text=True)
print(text1)

thu2 = thulac.thulac(seg_only=True)
text2 = thu2.cut("我爱北京天安门", text=True)
print(text2)