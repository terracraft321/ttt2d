import glob

storage = ''

for file_name in glob.glob('./*.lua'):
    with open(file_name, 'r') as f:
        storage += file_name + ':\n'
        for line in f:
            if 'function ' in line:
                storage += line[9:]
                
        storage += '\n'

print storage
