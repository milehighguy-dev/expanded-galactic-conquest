ParticleEmitter("Flare")
{
	MaxParticles(1.0000,1.0000);
	StartDelay(0.0000,0.0000);
	BurstDelay(0.0010, 0.0010);
	BurstCount(1.0000,1.0000);
	MaxLodDist(50.0000);
	MinLodDist(10.0000);
	BoundingRadius(5.0);
	SoundName("")
	NoRegisterStep();
	Size(1.0000, 1.0000);
	Hue(255.0000, 255.0000);
	Saturation(255.0000, 255.0000);
	Value(255.0000, 255.0000);
	Alpha(255.0000, 255.0000);
	Spawner()
	{
		Spread()
		{
			PositionX(0.0000,0.0000);
			PositionY(1.0000,1.0000);
			PositionZ(0.0000,0.0000);
		}
		Offset()
		{
			PositionX(0.0000,0.0000);
			PositionY(1.2500,1.2500);
			PositionZ(0.0000,0.0000);
		}
		PositionScale(0.0000,0.0000);
		VelocityScale(6.0000,6.0000);
		InheritVelocityFactor(0.0000,0.0000);
		Size(0, 1.0000, 1.0000);
		Red(0, 255.0000, 255.0000);
		Green(0, 255.0000, 255.0000);
		Blue(0, 255.0000, 255.0000);
		Alpha(0, 255.0000, 255.0000);
		StartRotation(0, 0.0000, 0.0000);
		RotationVelocity(0, 0.0000, 0.0000);
		FadeInTime(0.0000);
	}
	Transformer()
	{
		LifeTime(1.0000);
		Position()
		{
			LifeTime(1.0000)
		}
		Size(0)
		{
			LifeTime(0.5000)
		}
		Color(0)
		{
			LifeTime(0.5000)
			Reach(255.0000,255.0000,255.0000,0.0000);
		}
	}
	Geometry()
	{
		BlendMode("NORMAL");
		Type("EMITTER");
		Texture("com_sfx_flashring1");
		ParticleEmitter("Flare")
		{
			MaxParticles(6.0000,6.0000);
			StartDelay(0.0000,0.0000);
			BurstDelay(0.0300, 0.0300);
			BurstCount(1.0000,1.0000);
			MaxLodDist(50.0000);
			MinLodDist(10.0000);
			BoundingRadius(5.0);
			SoundName("")
			Size(1.0000, 1.0000);
			Hue(255.0000, 255.0000);
			Saturation(255.0000, 255.0000);
			Value(255.0000, 255.0000);
			Alpha(255.0000, 255.0000);
			Spawner()
			{
				Spread()
				{
					PositionX(0.0000,0.0000);
					PositionY(1.0000,1.0000);
					PositionZ(0.0000,0.0000);
				}
				Offset()
				{
					PositionX(0.0000,0.0000);
					PositionY(0.0000,0.0000);
					PositionZ(0.0000,0.0000);
				}
				PositionScale(0.0000,0.0000);
				VelocityScale(0.0000,0.0000);
				InheritVelocityFactor(0.0000,0.0000);
				Size(0, 0.5000, 0.5000);
				Red(0, 255.0000, 255.0000);
				Green(0, 0.0000, 0.0000);
				Blue(0, 0.0000, 0.0000);
				Alpha(0, 0.0000, 0.0000);
				StartRotation(0, 0.0000, 0.0000);
				RotationVelocity(0, 0.0000, 0.0000);
				FadeInTime(0.0000);
			}
			Transformer()
			{
				LifeTime(0.5000);
				Position()
				{
					LifeTime(1.0000)
				}
				Size(0)
				{
					LifeTime(1.5000)
					Scale(0.2500);
				}
				Color(0)
				{
					LifeTime(0.1000)
					Move(0.0000,0.0000,0.0000,128.0000);
					Next()
					{
						LifeTime(0.4000)
						Move(0.0000,0.0000,0.0000,-128.0000);
					}
				}
			}
			Geometry()
			{
				BlendMode("ADDITIVE");
				Type("BILLBOARD");
				Texture("com_sfx_flashring1");
			}
		}
	}
	ParticleEmitter("Flare")
	{
		MaxParticles(1.0000,1.0000);
		StartDelay(0.0000,0.0000);
		BurstDelay(0.0010, 0.0010);
		BurstCount(1.0000,1.0000);
		MaxLodDist(50.0000);
		MinLodDist(10.0000);
		BoundingRadius(5.0);
		SoundName("")
		NoRegisterStep();
		Size(1.0000, 1.0000);
		Hue(255.0000, 255.0000);
		Saturation(255.0000, 255.0000);
		Value(255.0000, 255.0000);
		Alpha(255.0000, 255.0000);
		Spawner()
		{
			Spread()
			{
				PositionX(0.0000,0.0000);
				PositionY(-1.0000,-1.0000);
				PositionZ(0.0000,0.0000);
			}
			Offset()
			{
				PositionX(0.0000,0.0000);
				PositionY(1.2500,1.2500);
				PositionZ(0.0000,0.0000);
			}
			PositionScale(0.0000,0.0000);
			VelocityScale(6.0000,6.0000);
			InheritVelocityFactor(0.0000,0.0000);
			Size(0, 1.0000, 1.0000);
			Red(0, 255.0000, 255.0000);
			Green(0, 255.0000, 255.0000);
			Blue(0, 255.0000, 255.0000);
			Alpha(0, 255.0000, 255.0000);
			StartRotation(0, 0.0000, 0.0000);
			RotationVelocity(0, 0.0000, 0.0000);
			FadeInTime(0.0000);
		}
		Transformer()
		{
			LifeTime(1.0000);
			Position()
			{
				LifeTime(1.0000)
			}
			Size(0)
			{
				LifeTime(0.5000)
			}
			Color(0)
			{
				LifeTime(0.5000)
				Reach(255.0000,255.0000,255.0000,0.0000);
			}
		}
		Geometry()
		{
			BlendMode("NORMAL");
			Type("EMITTER");
			Texture("com_sfx_flashring1");
			ParticleEmitter("Flare")
			{
				MaxParticles(6.0000,6.0000);
				StartDelay(0.0000,0.0000);
				BurstDelay(0.0300, 0.0300);
				BurstCount(1.0000,1.0000);
				MaxLodDist(50.0000);
				MinLodDist(10.0000);
				BoundingRadius(5.0);
				SoundName("")
				Size(1.0000, 1.0000);
				Hue(255.0000, 255.0000);
				Saturation(255.0000, 255.0000);
				Value(255.0000, 255.0000);
				Alpha(255.0000, 255.0000);
				Spawner()
				{
					Spread()
					{
						PositionX(0.0000,0.0000);
						PositionY(1.0000,1.0000);
						PositionZ(0.0000,0.0000);
					}
					Offset()
					{
						PositionX(0.0000,0.0000);
						PositionY(0.0000,0.0000);
						PositionZ(0.0000,0.0000);
					}
					PositionScale(0.0000,0.0000);
					VelocityScale(0.0000,0.0000);
					InheritVelocityFactor(0.0000,0.0000);
					Size(0, 0.5000, 0.5000);
					Red(0, 255.0000, 255.0000);
					Green(0, 0.0000, 0.0000);
					Blue(0, 0.0000, 0.0000);
					Alpha(0, 0.0000, 0.0000);
					StartRotation(0, 0.0000, 0.0000);
					RotationVelocity(0, 0.0000, 0.0000);
					FadeInTime(0.0000);
				}
				Transformer()
				{
					LifeTime(0.5000);
					Position()
					{
						LifeTime(1.0000)
					}
					Size(0)
					{
						LifeTime(1.5000)
						Scale(0.2500);
					}
					Color(0)
					{
						LifeTime(0.1000)
						Move(0.0000,0.0000,0.0000,128.0000);
						Next()
						{
							LifeTime(0.4000)
							Move(0.0000,0.0000,0.0000,-128.0000);
						}
					}
				}
				Geometry()
				{
					BlendMode("ADDITIVE");
					Type("BILLBOARD");
					Texture("com_sfx_flashring1");
				}
			}
		}
	}
}
