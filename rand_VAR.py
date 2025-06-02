import numpy as np
import matplotlib.pyplot as plt  # 히스토그램을 위한 라이브러리

# 파일에서 16진수 난수 읽기
with open("./py/rnd_output.txt", "r") as f:
    hex_values = [line.strip() for line in f if line.strip()]

# 정수로 변환
int_values = [int(val, 16) for val in hex_values]

# numpy로 계산
arr = np.array(int_values, dtype=np.uint32)
mean = np.mean(arr)
std_dev = np.std(arr)

print(f"Mean: {mean:.2f}")
print(f"Standard Deviation: {std_dev:.2f}")

# 히스토그램 시각화
plt.figure(figsize=(10, 6))
plt.hist(arr, bins=50, color='skyblue', edgecolor='black')
plt.title("Histogram of XORSHIFT128 Random Values")
plt.xlabel("Random Value")
plt.ylabel("Frequency")
plt.grid(True)
plt.tight_layout()
plt.show()
