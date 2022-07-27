# Do you want to store some stuff temporarily and you do not have document processor
# I got you :)

list_of_tokens = []
while True:
    new_token = input("Enter new session token")
    list_of_tokens.append(new_token)
    print(list_of_tokens)
    if new_token == "q":
        break
print(list_of_tokens)
print(len(list_of_tokens))