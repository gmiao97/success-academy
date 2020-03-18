# Generated by Django 3.0.2 on 2020-01-19 04:04

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('yoyaku', '0003_auto_20200119_0246'),
    ]

    operations = [
        migrations.AlterField(
            model_name='event',
            name='student_user',
            field=models.ManyToManyField(related_name='studentEvents', related_query_name='studentEvent', to='yoyaku.StudentProfile'),
        ),
        migrations.AlterField(
            model_name='event',
            name='teacher_user',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='teacherEvents', related_query_name='teacherEvent', to='yoyaku.TeacherProfile'),
        ),
    ]