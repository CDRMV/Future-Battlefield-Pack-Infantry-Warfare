#****************************************************************************
#**
#**  File     :  /cdimage/units/UES0103/UES0103_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UEF Frigate Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local TMobileFactoryUnit = import('/lua/terranunits.lua').TMobileFactoryUnit
local TAALinkedRailgun = import('/lua/terranweapons.lua').TAALinkedRailgun
local TDFGaussCannonWeapon = import('/lua/terranweapons.lua').TDFGaussCannonWeapon
local TIFHighBallisticMortarWeapon = import('/lua/terranweapons.lua').TIFHighBallisticMortarWeapon
local Entity = import('/lua/sim/Entity.lua').Entity

UES0010 = Class(TMobileFactoryUnit) {

    Weapons = {
        AAGun = Class(TAALinkedRailgun) {
        },
		MainGun1 = Class(TIFHighBallisticMortarWeapon) {
                
                CreateProjectileAtMuzzle = function(self, muzzle)
                    local proj = TIFHighBallisticMortarWeapon.CreateProjectileAtMuzzle(self, muzzle)
                    local data = {
                    Radius = self:GetBlueprint().CameraVisionRadius or 5,
                    Lifetime = self:GetBlueprint().CameraLifetime or 5,
                    Army = self.unit:GetArmy(),
                }
                if proj and not proj:BeenDestroyed() then
                    proj:PassData(data)
                end
            end,
        },
		MainGun2 = Class(TIFHighBallisticMortarWeapon) {
                
                CreateProjectileAtMuzzle = function(self, muzzle)
                    local proj = TIFHighBallisticMortarWeapon.CreateProjectileAtMuzzle(self, muzzle)
                    local data = {
                    Radius = self:GetBlueprint().CameraVisionRadius or 5,
                    Lifetime = self:GetBlueprint().CameraLifetime or 5,
                    Army = self.unit:GetArmy(),
                }
                if proj and not proj:BeenDestroyed() then
                    proj:PassData(data)
                end
            end,
        },
    },

    OnStopBeingBuilt = function(self,builder,layer)
        TMobileFactoryUnit.OnStopBeingBuilt(self,builder,layer)
        self.Trash:Add(CreateRotator(self, 'Spinner1', 'y', nil, 360, 0, 180))
        self.RadarEnt = Entity {}
        self.Trash:Add(self.RadarEnt)
        self.RadarEnt:InitIntel(self:GetArmy(), 'Radar', self:GetBlueprint().Intel.RadarRadius or 75)
        self.RadarEnt:EnableIntel('Radar')
        self.RadarEnt:InitIntel(self:GetArmy(), 'Sonar', self:GetBlueprint().Intel.SonarRadius or 75)
        self.RadarEnt:EnableIntel('Sonar')
        self.RadarEnt:AttachBoneTo(-1, self, 0)
    end,
	
	BuildAttachBone = 'Attachpoint',
	
	 OnStopBeingBuilt = function(self,builder,layer)
        self:SetWeaponEnabledByLabel('MainGun', true)
        TMobileFactoryUnit.OnStopBeingBuilt(self,builder,layer)
        if layer == 'Water' then
            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()
        else
            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
        end
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        TMobileFactoryUnit.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    OnMotionVertEventChange = function( self, new, old )
        TMobileFactoryUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()
            self:SetWeaponEnabledByLabel('FrontTurret02', true)
            self:PlayUnitSound('Open')
        elseif new == 'Down' then
            self:SetWeaponEnabledByLabel('FrontTurret02', false)
            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
            self:PlayUnitSound('Close')
        end
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
        end,

        OnStartBuild = function(self, unitBuilding, order)
            TMobileFactoryUnit.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
        end,
    },

    BuildingState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            self:SetBusy(true)
            local bone = self.BuildAttachBone
            self:DetachAll(bone)
            if not self.UnitBeingBuilt:IsDead() then
                unitBuilding:AttachBoneTo( 0, self, bone )
                if EntityCategoryContains(categories.INFANTRYLANDINGCRAFT) then
                    unitBuilding:SetParentOffset( {0,0,0} )

                else
                    unitBuilding:SetParentOffset( {0,0,0.0} )
                end
            end
            self.UnitDoneBeingBuilt = false
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            TMobileFactoryUnit.OnStopBuild(self, unitBeingBuilt)
            ChangeState(self, self.FinishedBuildingState)
        end,
    },

    FinishedBuildingState = State {
        Main = function(self)
		    if( not self.AnimManip ) then
				self.AnimManip = CreateAnimator(self)
			end
			self.AnimManip:PlayAnim(self:GetBlueprint().Display.AnimationFinishBuild)
            self.AnimManip:SetAnimationFraction(2)
            self.AnimManip:SetRate(0.2)
			self.IsWaiting = true
            self:SetBusy(true)
            local unitBuilding = self.UnitBeingBuilt
            unitBuilding:DetachFrom(true)
            self:DetachAll(self.BuildAttachBone)
            local worldPos = self:CalculateWorldPositionFromRelative({0, 0, 20})
            IssueMoveOffFactory({unitBuilding}, worldPos)
            self:SetBusy(false)
            ChangeState(self, self.IdleState)		
			self.AnimManip:PlayAnim(self:GetBlueprint().Display.AnimationFinishBuild)
            self.AnimManip:SetAnimationFraction(2)
            self.AnimManip:SetRate(-0.2)
        end,
    },	
}

TypeClass = UES0010