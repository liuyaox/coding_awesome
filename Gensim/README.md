# Gensim

**Tutorial**: <https://radimrehurek.com/gensim/tutorial.html>




## Summarization

文本摘要，文本总结

```python
from gensim.summarization import summarize
sentence = '''Technologies that can make a ... Search engines are an example; 
    others include summarization of documents'''
summarize(sentence)
```