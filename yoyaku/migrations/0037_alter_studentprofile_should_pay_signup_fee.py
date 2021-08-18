# Generated by Django 3.2.4 on 2021-07-04 22:10

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('yoyaku', '0036_auto_20210614_0329'),
    ]

    operations = [
        migrations.AlterField(
            model_name='studentprofile',
            name='should_pay_signup_fee',
            field=models.CharField(choices=[('pay_full', 'pay_full'), ('paid_full', 'paid_full'), ('pay_10', 'pay_10'), ('paid_10', 'paid_10'), ('referral', 'referral')], default='referral', max_length=30, verbose_name='pay sign up'),
        ),
    ]
