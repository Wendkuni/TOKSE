import '../../../feed/data/models/signalement_model.dart';
import '../../domain/entities/signalement_entity.dart';

/// Mapper entre SignalementModel (Data) et SignalementEntity (Domain)
extension SignalementModelMapper on SignalementModel {
  SignalementEntity toEntity() {
    return SignalementEntity(
      id: id,
      titre: titre,
      description: description,
      categorie: categorie,
      etat: etat,
      latitude: latitude,
      longitude: longitude,
      adresse: adresse,
      userId: userId,
      author: author != null
          ? UserAuthor(
              id: author!.id,
              nom: author!.nom,
              prenom: author!.prenom,
              avatarUrl: author!.photoProfile,
            )
          : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
      photoUrl: photoUrl,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
      felicitations: felicitations,
    );
  }
}

extension SignalementEntityMapper on SignalementEntity {
  SignalementModel toModel() {
    return SignalementModel(
      id: id,
      userId: userId,
      titre: titre,
      description: description,
      categorie: categorie,
      etat: etat,
      latitude: latitude,
      longitude: longitude,
      adresse: adresse,
      photoUrl: photoUrl,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
      felicitations: felicitations,
      createdAt: createdAt,
      updatedAt: updatedAt,
      author: author != null
          ? UserProfile(
              id: author!.id,
              nom: author!.nom ?? '',
              prenom: author!.prenom ?? '',
              photoProfile: author!.avatarUrl,
            )
          : null,
    );
  }
}
