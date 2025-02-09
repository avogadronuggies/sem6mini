from django.shortcuts import redirect, render

def index(request):
    return render(request, 'main/index.html')

def login(request):
    # if request.method == "POST":
    #     role = request.POST.get("role")
    #     user_id = request.POST.get("user_id")
    #     password = request.POST.get("password")

    #     if role == "student":
    #         # Authenticate student
    #         return redirect("student_dashboard")
    #     elif role == "staff":
    #         # Authenticate staff
    #         return redirect("staff_dashboard")
    #     elif role == "parent":
    #         # Authenticate parent
    #         return redirect("parent_dashboard")

    return render(request, 'main/login.html')
