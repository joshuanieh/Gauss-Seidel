
b = [248,-682,24710,-9624,-3313,30377,-29996,30995,-20368,10952,5665,11476,-9108,7882,20391,-31505]
#x = [12.4,-34.1,1235.5,-481.2,-165.65,1518.85,-1499.8,1549.75,-1018.4,547.6,283.25,573.8,-455.4,394.1,1019.55,-1575.25]
x = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
a = [0,4,8,12,1,5,9,13,2,6,10,14,3,7,11,15]


n = 50   #times of iteration
mode = 1   # 0 : pipeline    , 1 : non-pipeline
order = 1  # 0 : 1,2,3,4..,  , 1 : 1,5,9,13,...

temp = -1
print("======= ", n, " =======")
if mode:
    print("** non pipeline **")
else: print("** pipeline **") 

if order:
    print("** 1,5,9,13,... **")
else: print("** 1,2,3,4,... **")

if order == 0:
    for i in range(n):
        for j in range(16):
            if j == 15:
                x1 = 0
            else: x1 = x[j+1] 
            if j == 0:
                x2 = 0
            else: x2 = x[j-1]
            if j == 15 or j == 14:
                x3 = 0
            else: x3 = x[j+2]
            if j == 0 or j == 1:
                x4 = 0
            else: x4 = x[j-2]
            if j == 15 or j == 14 or j == 13:
                x5 = 0
            else: x5 = x[j+3]
            if j == 0 or j == 1 or j == 2:
                x6 = 0
            else: x6 = x[j-3]
            

            if mode == 0:
                if i + j > 0:
                    if j > 0:
                        x[j-1] = temp                      # pipeline version
                    else: 
                        x[15] = temp
                temp = (b[j] + 13*(x1 + x2) - 6*(x3 + x4) + (x5 + x6)) / 20
            else:
                x[j] = (b[j] + 13*(x1 + x2) - 6*(x3 + x4) + (x5 + x6)) / 20          # non-pipeline version


    # =========== x1, x5, x9, x13, x2,... ===========
else:
    for i in range(n):
        for k in range(16):
            j = a[k]
            if j == 15:
                x1 = 0
            else: x1 = x[j+1] 
            if j == 0:
                x2 = 0
            else: x2 = x[j-1]
            if j == 15 or j == 14:
                x3 = 0
            else: x3 = x[j+2]
            if j == 0 or j == 1:
                x4 = 0
            else: x4 = x[j-2]
            if j == 15 or j == 14 or j == 13:
                x5 = 0
            else: x5 = x[j+3]
            if j == 0 or j == 1 or j == 2:
                x6 = 0
            else: x6 = x[j-3]

            if mode == 0:
                if i + k > 0:
                    if k > 0:
                        x[a[k-1]] = temp                      # pipeline version
                    else: 
                        x[15] = temp
                temp = (b[j] + 13*(x1 + x2) - 6*(x3 + x4) + (x5 + x6)) / 20
            else:
                x[j] = (b[j] + 13*(x1 + x2) - 6*(x3 + x4) + (x5 + x6)) / 20           

print(x)
