import requests
import pandas as pd

# 真实API地址：世界银行教育数据（学生学习时长相关）
api_url = "http://api.worldbank.org/v2/country/all/indicator/SE.XPD.TOTL.GD.ZS?format=json&per_page=1000"

# 调用API（世界银行API需要加个参数指定语言）
response = requests.get(api_url, params={"lang": "en"})
data = response.json()[1]  # 提取数据部分

# 整理成表格，保存为CSV（美赛直接用）
df = pd.DataFrame(data)
df = df[["countryiso3code", "date", "value"]]  # 只保留核心列
df.columns = ["国家代码", "年份", "教育投入占GDP比例"]  # 重命名列（方便你看）
df.to_csv("C:/Users/17934/Desktop/美赛_世界银行教育数据.csv", index=False, encoding="utf-8")

print("数据获取成功！已保存为CSV文件")