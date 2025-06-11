with open('text_font.txt', 'r', encoding='utf-8') as f:
    lines = [line.rstrip('\n') for line in f]

# lines 리스트에 한 줄씩 저장됨
print(lines)
with open('output.txt', 'w', encoding='utf-8') as f_out:
    for line in lines:
        f_out.write(line + '\n')