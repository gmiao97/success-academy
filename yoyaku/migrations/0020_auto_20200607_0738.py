# Generated by Django 3.0.4 on 2020-06-07 07:38

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('yoyaku', '0019_auto_20200607_0731'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='event',
            name='backgroundColor',
        ),
        migrations.AddField(
            model_name='event',
            name='color',
            field=models.CharField(default='blue', max_length=10, verbose_name='color'),
        ),
    ]