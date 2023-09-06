from django.core.management.base import BaseCommand, CommandError
import csv
from datetime import datetime

from waatea_2.users.models import User, UserProfile
from waateaapp.models import Availability, Season, Club


#Imports users, creates standard password
#create a folder data and copy the source csv into this folder
#CSV should be email;name;phone

class Command(BaseCommand):
    def add_arguments(self, parser):
        parser.add_argument('filename')
        parser.add_argument('clubid')
        parser.add_argument('seasonid')
    def handle(self, *args, **kwargs):
        filename = kwargs['filename']
        clubid=kwargs['clubid']
        seasonid=kwargs['seasonid']
        print(filename)
        file_path = filename  # Path to the mounted CSV file

        club = Club.objects.get(pk=clubid)
        season = Season.objects.get(pk=seasonid)


        with open(file_path, 'r') as csv_file:
            reader = csv.reader(csv_file)
            for row in reader:
                try:


                    print("Load player")
                    player = User.objects.get(email=row[4])

                    print("Convert date")
                    datetime_format = "%Y-%m-%d %H:%M"
                    aval_date = datetime.strptime(row[3] + " 06:00", datetime_format)
                    dayofyear = aval_date.timetuple().tm_yday

                    #Old Waatea
                    #2=unavail
                    #3=avail
                    #1=maybe

                    #New Waatea:
                    #1=unavail
                    #2=maybe
                    #3=avail

                    state = 0

                    if (row[5] == "1"):
                        state = 2
                    if (row[5] == "2"):
                        state = 1
                    if (row[5] == "3"):
                        state = 3

                    print(player.pk)

                    availability, created = Availability.objects.get_or_create(
                        player=player,
                        season=season,
                        club=club,
                        dayofyear=dayofyear,
                        state=state
                    )

                    # Set password for the user
                    availability.save()

                    self.stdout.write(self.style.SUCCESS(f'Successfully created availability: {row[4]}/{row[3]}'))
                    # Process each row as needed
                    print(row[0])
                except User.DoesNotExist:
                    self.stdout.write(self.style.ERROR(f'User does not exist: {row[4]}'))
              #  except:
              #     self.stdout.write(self.style.ERROR(f'Failed to create availability: {row[4]}/{row[3]}'))


