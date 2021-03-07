# Generated by Django 3.0.7 on 2021-02-15 17:57

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('yoyaku', '0032_auto_20210118_1751'),
    ]

    operations = [
        migrations.CreateModel(
            name='PreschoolClass',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=300, verbose_name='preschool class name')),
                ('limit', models.IntegerField(verbose_name='max class size')),
            ],
        ),
        migrations.AddField(
            model_name='studentprofile',
            name='preschool',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='yoyaku.PreschoolClass'),
        ),
    ]
