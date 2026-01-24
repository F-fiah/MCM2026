import requests
from bs4 import BeautifulSoup
import pandas as pd

# 1. 要爬的网页地址（公开的教育统计网页，可替换）
web_url = "https://www.example.com/student_study_data.html"
# 2. 爬取网页数据
response = requests.get(web_url)
soup = BeautifulSoup(response.text, 'html.parser')
# 3. 提取网页里的表格数据（美赛99%是表格数据）
table = soup.find('table')
rows = table.find_all('tr')
# 4. 整理成表格，保存为CSV
data_list = []
for row in rows:
    cols = row.find_all('td')
    cols = [col.text.strip() for col in cols]
    data_list.append(cols)
df = pd.DataFrame(data_list)
df.to_csv("美赛_爬虫学习时长数据.csv", index=False, encoding='utf-8')
print("爬虫数据爬取完成！已保存为CSV文件")