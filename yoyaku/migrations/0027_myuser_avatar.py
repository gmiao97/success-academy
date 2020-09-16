# Generated by Django 3.0.7 on 2020-09-12 05:48

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('yoyaku', '0026_auto_20200821_0213'),
    ]

    operations = [
        migrations.AddField(
            model_name='myuser',
            name='avatar',
            field=models.CharField(blank=True, choices=[('bear', 'Bear'), ('cat', 'Cat'), ('deer', 'Deer'), ('dog', 'Dog'), ('fox', 'Fox'), ('giraffe', 'Giraffe'), ('gorilla', 'Gorilla'), ('koala', 'Koala'), ('llama', 'Llama'), ('panda', 'Panda'), ('pug', 'Pug'), ('rabbit', 'Rabbit'), ('raccoon', 'Raccoon'), ('reindeer', 'Reindeer'), ('skunk', 'Skunk'), ('wolf', 'Wolf')], max_length=10, verbose_name='avatar'),
        ),
    ]