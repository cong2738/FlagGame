import numpy as np
import matplotlib.pyplot as plt  # 히스토그램을 위한 라이브러리
import os

base_dir = os.path.dirname(os.path.abspath(__file__))  # py파일이 있는 디렉토리
file_path = os.path.join(base_dir, "rnd_output.txt")

# 파일에서 16진수 난수 읽기
try:
    with open(file_path, "r") as f:
        hex_values = [line.strip() for line in f if line.strip()]
except:
    print("File Open Error...")

# 정수로 변환
int_values = [int(val, 16) for val in hex_values]

# numpy로 계산
arr = np.array(int_values, dtype=np.uint32)
mean = np.mean(arr)
std_dev = np.std(arr)

print(f"Mean: {mean:.2f}")
print(f"Standard Deviation: {std_dev:.2f}")

plt.figure(figsize=(12, 6))
plt.hist(arr, bins=500, color='skyblue', edgecolor='black')  # 구간 수 증가
plt.title("Histogram of XORSHIFT128 Random Values", fontsize=15)
plt.xlabel("Random Value", fontsize=13)
plt.ylabel("Frequency", fontsize=13)
plt.grid(True)
plt.tight_layout()
plt.show()