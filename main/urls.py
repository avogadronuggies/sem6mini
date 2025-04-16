from django.urls import path
from .views import index, login
from . import views

urlpatterns = [
    path('', index, name='index'),
    path('login', login, name='login'),
    path('student_dashboard/', views.student_dashboard, name='student_dashboard'),
    path('teacher_dashboard/', views.teacher_dashboard, name='teacher_dashboard'),
    path('parent_dashboard/', views.parent_dashboard, name='parent_dashboard'),
    path('logout/', views.logout, name='logout'),
]
