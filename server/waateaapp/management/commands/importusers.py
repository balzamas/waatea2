from django.core.management.base import BaseCommand, CommandError
import csv

from waatea_2.users.models import User, UserProfile
from waateaapp.model_club import Club


#Imports users, creates standard password
#create a folder data and copy the source csv into this folder
#CSV should be email;name;phone

class Command(BaseCommand):
    def add_arguments(self, parser):
        parser.add_argument('filename')
        parser.add_argument('clubid')
    def handle(self, *args, **kwargs):
        filename = kwargs['filename']
        clubid=kwargs['clubid']
        print(filename)
        file_path = filename  # Path to the mounted CSV file

        club = Club.objects.get(pk=clubid)

        with open(file_path, 'r') as csv_file:
            reader = csv.reader(csv_file)
            for row in reader:
                try:

                    user, created = User.objects.get_or_create(
                        email=row[0],
                        name=row[1],
                        club=club,
                    )

                    # Set password for the user
                    user.set_password(row[0].split("@")[0] + '12345')
                    user.save()

                    if created:
                        profile, _ = UserProfile.objects.get_or_create(user=user)

                    # Update the mobile_phone field in the profile
                    profile.mobile_phone = row[2]  # Set the actual mobile phone value
                    profile.save()

                    self.stdout.write(self.style.SUCCESS(f'Successfully created user: {row[0]}'))
                    # Process each row as needed
                    print(row[0])
                except:
                   self.stdout.write(self.style.ERROR(f'Failed to create user: {row[0]}'))


