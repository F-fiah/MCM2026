import matplotlib.pyplot as plt
import numpy as np

# -------------------------- 1. 基础参数设置 --------------------------
# 12个月份
months = ['Jan.', 'Feb.', 'Mar.', 'Apr.', 'May', 'Jun.', 
          'Jul.', 'Aug.', 'Sep.', 'Oct.', 'Nov.', 'Dec.']
# 四个生命周期阶段对应的月份索引（0-11）
stages = {
    'Wintering': [11, 0, 1],       # 12、1、2月
    'Foundation': [2, 3, 4],       # 3、4、5月
    'Growth': [5, 6, 7],           # 6、7、8月
    'Reproduction': [8, 9, 10]     # 9、10、11月
}
# 各阶段对应的颜色（匹配原图风格）
colors = {
    'Wintering': '#B4C7E7',        # 浅蓝色
    'Foundation': '#F9E0A2',       # 浅黄色
    'Growth': '#C5E0B4',           # 浅绿色
    'Reproduction': '#F4CCCC'      # 浅红色
}
# 环形图基础参数
n_sectors = 12                     # 12个扇区
values = np.ones(n_sectors)        # 每个扇区数值相等（保证大小一致）
inner_radius = 0.7                # 内环半径（控制环形粗细）
outer_radius = 1.0                # 外环半径

# -------------------------- 2. 创建画布与绘制环形 --------------------------
fig, ax = plt.subplots(figsize=(8, 8), dpi=100)
# 绘制环形图（饼图+挖空内环）
wedges, texts = ax.pie(
    values,
    radius=outer_radius,
    wedgeprops=dict(width=outer_radius - inner_radius, edgecolor='white', linewidth=1),
    startangle=90,  # 从正上方开始（Jan.在顶部）
    counterclock=False  # 顺时针排列月份
)

# -------------------------- 3. 为扇区分配对应颜色 --------------------------
for stage, indices in stages.items():
    for idx in indices:
        wedges[idx].set_facecolor(colors[stage])

# -------------------------- 4. 添加月份文字标注 --------------------------
# 计算每个扇区的中心角度，用于放置文字
angles = np.linspace(0, 2 * np.pi, n_sectors, endpoint=False) + np.pi/12  # 偏移半个扇区角度
for i, (month, angle) in enumerate(zip(months, angles)):
    # 计算文字位置（在扇区中间）
    x = (inner_radius + (outer_radius - inner_radius)/2) * np.cos(angle)
    y = (inner_radius + (outer_radius - inner_radius)/2) * np.sin(angle)
    # 添加文字
    ax.text(
        x, y, month,
        ha='center', va='center', fontsize=10, fontfamily='Arial',
        color='black', weight='bold'
    )

# -------------------------- 5. 添加阶段标题标注 --------------------------
# 阶段标题的位置（环形外侧）
stage_positions = {
    'Wintering': (0, 1.15),        # 顶部
    'Foundation': (-1.15, 0),      # 左侧
    'Growth': (0, -1.15),          # 底部
    'Reproduction': (1.15, 0)      # 右侧
}
for stage, pos in stage_positions.items():
    ax.text(
        pos[0], pos[1], stage,
        ha='center', va='center', fontsize=12, fontfamily='Arial',
        color=colors[stage], weight='bold'
    )

# -------------------------- 6. 美化与导出 --------------------------
ax.set_aspect('equal')  # 保证环形为正圆形
plt.axis('off')         # 隐藏坐标轴
plt.tight_layout()      # 自动调整布局
# 保存图片（高清无白边）
plt.savefig('hornet_lifecycle.png', dpi=300, bbox_inches='tight', pad_inches=0.1)
plt.show()