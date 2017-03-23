Use Comm4
If OBJECT_ID('tempdb..#newDefaults') Is Not NULL
Drop Table #newDefaults
Create Table #newDefaults (SettingType varchar(30), ID int,
DefaultSetting varchar(max));
Insert Into #newDefaults values ('Config', 1202, '500')
Insert Into #newDefaults values ('Config', 206, '70')
Insert Into #newDefaults values ('Preference', 103, 'True')
Insert Into #newDefaults values ('Preference', 403, '0')
Insert Into #newDefaults values ('Preference', 702, '2')
Insert Into #newDefaults values ('Preference', 242, '3')
Insert Into #newDefaults values ('Preference', 109, 'True')
Insert Into #newDefaults values ('Preference', 208, 'True')
Insert Into #newDefaults values ('Preference', 213, 'True')
Insert Into #newDefaults values ('Preference', 231, 'True')
Insert Into #newDefaults values ('Preference', 246, 'False')
Insert Into #newDefaults values ('Preference', 710, 'True')
Insert Into #newDefaults values ('Preference', 711, 'True')
Insert Into #newDefaults values ('Preference', 415, 'True')
Insert Into #newDefaults values ('Preference', 1181, '1')
Insert Into #newDefaults values ('Preference', 1169, 'False')
Insert Into #newDefaults values ('Preference', 1128, 'False')
Insert Into #newDefaults values ('Preference', 1155, 'False')
Insert Into #newDefaults values ('Preference', 1139, '2')
Insert Into #newDefaults values ('Preference', 1147, '3')
Insert Into #newDefaults values ('Bridge Option', 24, 'False')
Insert Into #newDefaults values ('Bridge Option', 30, 'True')
Insert Into #newDefaults values ('Bridge Option', 40, 'False')

Select 'Config' As "Setting Type", Config.Name as "Setting Name",
Config.DefaultSetting as "Existing Default",
#newDefaults.DefaultSetting as "New Default"
from Config
inner join #newDefaults on #newDefaults.SettingType='Config' and
Config.ConfigID=#newDefaults.ID
where
Setting Is null Or ltrim(setting) = ''
Union All
Select 'Preference', p.Name, p.DefaultSetting, #newDefaults.DefaultSetting

from Preference p
inner join #newDefaults on #newDefaults.SettingType='Preference'
and P.PreferenceID=#newDefaults.ID
where
p. PreferenceID not in
(
Select PreferenceID from SystemPreference
union
Select PreferenceID from SitePreference
Union
Select PreferenceID from AccountPreference
)
Union All
Select 'Brdge Option', p.Name, p.DefaultSetting,
#newDefaults.DefaultSetting
from BridgeOption p Left join SiteBridgeOption sp on
sp.BridgeOptionID = p.BridgeOptionID
inner join #newDefaults on #newDefaults.SettingType='Bridge
Option' and p.BridgeOptionID=#newDefaults.ID
where
sp.BridgeOptionID is null
GO
